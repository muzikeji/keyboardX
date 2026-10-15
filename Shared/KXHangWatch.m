//
//  KXHangWatch.m
//  keyboardX —— 主线程卡顿采样器实现
//

#import "KXHangWatch.h"
#import "KXBootTrace.h"

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach/thread_act.h>
#import <mach/arm/thread_status.h>
#import <mach/vm_map.h>
#import <dlfcn.h>
#import <pthread.h>
#import <stdio.h>
#import <string.h>
#import <unistd.h>
#import <fcntl.h>

#define KX_HANG_LOG KX_TRACE_DIR "/hang.log"
#define KX_HANG_PING_TIMEOUT_SEC 2
#define KX_HANG_MAX_FRAMES 40

// 主线程的 Mach port 必须在主线程上、卡住之前取到，之后由采样线程使用。
static mach_port_t kx_main_thread_port = MACH_PORT_NULL;

static void KXHangWrite(const char *text) {
    if (!text || !*text) return;
    int fd = open(KX_HANG_LOG, O_WRONLY | O_CREAT | O_APPEND, 0666);
    if (fd < 0) return;
    ssize_t ignored = write(fd, text, strlen(text));
    (void)ignored;
    close(fd);
}

// 挂起主线程，抓取 PC/LR 与帧指针链上的返回地址；恢复后再符号化。
static void KXSampleMainThread(void) {
    if (kx_main_thread_port == MACH_PORT_NULL) return;
    if (thread_suspend(kx_main_thread_port) != KERN_SUCCESS) return;

    uint64_t addrs[KX_HANG_MAX_FRAMES];
    int count = 0;
    uint64_t pc = 0, lr = 0;

    arm_thread_state64_t state;
    mach_msg_type_number_t stateCount = ARM_THREAD_STATE64_COUNT;
    if (thread_get_state(kx_main_thread_port, ARM_THREAD_STATE64,
                         (thread_state_t)&state, &stateCount) == KERN_SUCCESS) {
        // arm64e 启用了指针认证，__pc/__lr/__fp 不能直接读，
        // 必须用访问器宏（它们会剥掉 PAC 签名位）。
        pc = arm_thread_state64_get_pc(state);
        lr = arm_thread_state64_get_lr(state);
        uint64_t fp = arm_thread_state64_get_fp(state);
        for (int i = 0; i < KX_HANG_MAX_FRAMES && fp != 0; i++) {
            uint64_t frame[2] = {0, 0};
            vm_size_t size = sizeof(frame);
            if (vm_read_overwrite(mach_task_self(), (vm_address_t)fp,
                                  sizeof(frame), (vm_address_t)frame, &size) != KERN_SUCCESS) {
                break;
            }
            uint64_t nextFp = frame[0], retAddr = frame[1];
            if (retAddr == 0) break;
            addrs[count++] = retAddr;
            // 帧指针必须严格递增，否则说明不是有效帧链，立即停止避免死循环。
            if (nextFp <= fp) break;
            fp = nextFp;
        }
    }
    thread_resume(kx_main_thread_port);

    char buf[8192];
    int n = 0;
    struct timeval tv;
    gettimeofday(&tv, NULL);
    n += snprintf(buf + n, sizeof(buf) - n,
                  "\n===== MAIN THREAD STALL %ld.%06d pid=%d =====\n",
                  (long)tv.tv_sec, (int)tv.tv_usec, (int)getpid());
    if (pc) n += snprintf(buf + n, sizeof(buf) - n, "  pc %#llx  lr %#llx\n",
                          (unsigned long long)pc, (unsigned long long)lr);
    for (int i = 0; i < count && n < (int)sizeof(buf) - 256; i++) {
        Dl_info info;
        if (dladdr((void *)(uintptr_t)addrs[i], &info) && info.dli_fname) {
            const char *sym = info.dli_sname ? info.dli_sname : info.dli_fname;
            n += snprintf(buf + n, sizeof(buf) - n, "  #%-2d %s + %#llx\n", i,
                          sym, (unsigned long long)(addrs[i] - (uint64_t)info.dli_fbase));
        } else {
            n += snprintf(buf + n, sizeof(buf) - n, "  #%-2d %#llx\n", i,
                          (unsigned long long)addrs[i]);
        }
    }
    KXHangWrite(buf);
}

void KXStartHangWatch(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // 独立开关：enable-hangwatch（或 enable-trace）。
        // 之所以不强制复用 enable-trace，是因为打开逐步骤追踪本身会给每个被
        // hook 的进程带来额外开销，会干扰"CPU 被谁占满"的观测。
        //   touch /var/mobile/Library/KeyboardX/enable-hangwatch
        if (access(KX_TRACE_DIR "/enable-hangwatch", F_OK) != 0 &&
            access(KX_TRACE_DIR "/enable-trace", F_OK) != 0) return;

        // Mach port 必须在主线程上取，且要在卡住之前。
        if ([NSThread isMainThread]) {
            kx_main_thread_port = pthread_mach_thread_np(pthread_self());
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
              kx_main_thread_port = pthread_mach_thread_np(pthread_self());
            });
        }
        if (kx_main_thread_port == MACH_PORT_NULL) return;

        KXHangWrite("\n[hangwatch] started (threshold=2s)\n");

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
          for (;;) {
              @autoreleasepool {
                  dispatch_semaphore_t ping = dispatch_semaphore_create(0);
                  dispatch_async(dispatch_get_main_queue(), ^{ dispatch_semaphore_signal(ping); });
                  dispatch_time_t deadline =
                      dispatch_time(DISPATCH_TIME_NOW, (int64_t)KX_HANG_PING_TIMEOUT_SEC * NSEC_PER_SEC);

                  if (dispatch_semaphore_wait(ping, deadline) != 0) {
                      // 主线程 3 秒没跑 run loop：连续采样，把栈写进 hang.log。
                      for (int i = 0; i < 5; i++) {
                          KXSampleMainThread();
                          sleep(1);
                      }
                      // 等主线程恢复，避免连续刷屏。
                      dispatch_semaphore_t wait = dispatch_semaphore_create(0);
                      dispatch_async(dispatch_get_main_queue(), ^{ dispatch_semaphore_signal(wait); });
                      dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER);
                  }
              }
              sleep(1);
          }
        });
    });
}

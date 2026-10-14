//
//  KXBootTrace.h
//  keyboardX —— 加载期追踪 + 组件级熔断
//
//  用途：SpringBoard 一装就安全模式时，无法交互调试。本文件提供两个能力：
//
//  1) KXTrace(component, stage)
//     把加载期每一步追加写入 /var/mobile/Library/KeyboardX/boot.log 并 NSLog。
//     安全模式后读这个文件，即可知道崩溃发生在哪一个组件、哪一步之前。
//
//  2) 熔断开关（纯文件存在性判断，安全模式下用 Filza/SSH 建文件即可生效）
//     /var/mobile/Library/KeyboardX/disable-all            关闭全部组件
//     /var/mobile/Library/KeyboardX/disable-typex          关闭 TypeX（键盘增强）
//     /var/mobile/Library/KeyboardX/disable-kayoko-helper  关闭 Kayoko 键盘侧
//     /var/mobile/Library/KeyboardX/disable-kayoko-core    关闭 Kayoko 核心（SpringBoard 侧）
//
//  设计约束：本文件在 +load / constructor 阶段被调用，必须绝对安全。
//  因此只用 POSIX 的 open/write/close/access，不依赖 Foundation 对象，
//  任何一步失败都静默返回，绝不抛异常、绝不递归。
//

#ifndef KX_BOOT_TRACE_H
#define KX_BOOT_TRACE_H

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/time.h>

#define KX_TRACE_DIR "/var/mobile/Library/KeyboardX"
#define KX_TRACE_LOG KX_TRACE_DIR "/boot.log"

// 目录只尝试创建一次，避免每个 trace 点都走一次 stat。
static int kx_trace_dir_ready = 0;

static inline void KXTraceEnsureDir(void) {
    if (kx_trace_dir_ready) return;
    if (access(KX_TRACE_DIR, F_OK) != 0) {
        mkdir(KX_TRACE_DIR, 0777);
    }
    // 目录可能存在但不可写（沙盒进程），这里不做判断，
    // 由 open() 失败兜底，避免多余的 syscall。
    kx_trace_dir_ready = 1;
}

// component: "typex" / "kayoko-helper" / "kayoko-core"
// stage:     简短英文步骤名，避免编码问题
static inline void KXTrace(const char *component, const char *stage) {
    KXTraceEnsureDir();

    int fd = open(KX_TRACE_LOG, O_WRONLY | O_CREAT | O_APPEND, 0666);
    if (fd < 0) return;

    struct timeval tv;
    gettimeofday(&tv, NULL);

    char buf[512];
    int n = snprintf(buf, sizeof(buf), "%ld.%06d [%s] %s (pid=%d)\n",
                     (long)tv.tv_sec, (int)tv.tv_usec,
                     component ? component : "?", stage ? stage : "?", (int)getpid());
    if (n > 0) {
        ssize_t ignored = write(fd, buf, (size_t)n);
        (void)ignored;
    }
    close(fd);

    // 同时打 NSLog，便于 idevicesyslog / Console.app 实时观察。
    printf("[keyboardX] %s: %s\n", component ? component : "?", stage ? stage : "?");
}

// 组件级熔断：文件存在即视为"关闭该组件"。
static inline int KXDisabled(const char *component) {
    if (!component) return 0;
    char path[256];
    snprintf(path, sizeof(path), KX_TRACE_DIR "/disable-%s", component);
    return access(path, F_OK) == 0;
}

// 全局熔断：安全模式下建这一个文件即可让插件完全不挂钩。
static inline int KXAllDisabled(void) {
    return access(KX_TRACE_DIR "/disable-all", F_OK) == 0;
}

// 统一的"该组件是否应当跳过"判断。
static inline int KXShouldSkip(const char *component) {
    if (KXAllDisabled()) return 1;
    return KXDisabled(component);
}

#endif /* KX_BOOT_TRACE_H */

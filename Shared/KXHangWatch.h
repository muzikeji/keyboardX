//
//  KXHangWatch.h
//  keyboardX —— 主线程卡顿采样器
//
//  用途：界面卡死/CPU 拉满但无崩溃日志时，定位到底是谁在占着主线程。
//
//  原理：后台线程每秒向主线程派发一个空块。若 3 秒内没有执行完，判定主线程被
//  卡住，于是挂起主线程、读取 PC/LR 与帧指针链，**恢复主线程之后**再用 dladdr
//  符号化（绝不在挂起状态下调用 dladdr，否则可能与 dyld 锁互等），把调用栈
//  追加写入 /var/mobile/Library/KeyboardX/hang.log。
//
//  默认关闭：仅当 /var/mobile/Library/KeyboardX/enable-trace 存在时启动，
//  与 KXTrace 共用同一个开关。开启方式：
//      touch /var/mobile/Library/KeyboardX/enable-trace
//

#ifndef KX_HANG_WATCH_H
#define KX_HANG_WATCH_H

#ifdef __cplusplus
extern "C" {
#endif

// 幂等：重复调用只会启动一次。仅应在 SpringBoard 内调用。
void KXStartHangWatch(void);

#ifdef __cplusplus
}
#endif

#endif /* KX_HANG_WATCH_H */

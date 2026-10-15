#import "DXFloatingAppShelfChannel.h"
#import <notify.h>

const char *DXFloatingShelfChangedName = "com.lindo.typex.floating-shelf.v1";
static const NSUInteger DXFloatingShelfMaxBytes = 8192;
static NSMutableDictionary<NSString *, NSNumber *> *DXShelfPinned;
static uint64_t DXShelfRevision;
static NSString *DXShelfSlot(NSUInteger bank, NSString *suffix) {
    return [NSString stringWithFormat:@"%s.%lu.%@", DXFloatingShelfChangedName, (unsigned long)bank, suffix];
}
static BOOL DXShelfWrite(NSString *name, uint64_t word) {
    NSNumber *existing = DXShelfPinned[name];
    int token = existing ? existing.intValue : NOTIFY_TOKEN_INVALID;
    if (!existing) {
        if (notify_register_check(name.UTF8String, &token) != NOTIFY_STATUS_OK) return NO;
        DXShelfPinned[name] = @(token);
    }
    return notify_set_state(token, word) == NOTIFY_STATUS_OK;
}
// 读取用的 notify token 必须缓存。
// 原实现对每个 8 字节槽位都做一次 notify_register_check 并在读完后 notify_cancel，
// 也就是每读一个槽位要 3 次 Mach IPC。一个几百字节的快照就是数百次 IPC，而读取
// 发生在键盘停靠栏的刷新路径上（每个 App、每次键盘弹出），足以把 CPU 拉满。
// 注册一次并长期持有后，每次读取只剩 1 次 notify_get_state。
static NSMutableDictionary<NSString *, NSNumber *> *DXShelfReadTokens;
static BOOL DXShelfRead(NSString *name, uint64_t *word) {
    if (!DXShelfReadTokens) DXShelfReadTokens = [NSMutableDictionary dictionary];
    NSNumber *cached = DXShelfReadTokens[name];
    int token = NOTIFY_TOKEN_INVALID;
    if (cached) {
        token = cached.intValue;
    } else {
        if (notify_register_check(name.UTF8String, &token) != NOTIFY_STATUS_OK) return NO;
        DXShelfReadTokens[name] = @(token);
    }
    return notify_get_state(token, word) == NOTIFY_STATUS_OK;
}
BOOL DXPublishFloatingShelf(NSDictionary *snapshot) {
    if (!NSThread.isMainThread || ![NSProcessInfo.processInfo.processName isEqual:@"SpringBoard"] ||
        !DXFloatingShelfSnapshotValid(snapshot)) return NO;
    if (!DXShelfPinned) {
        DXShelfPinned = [NSMutableDictionary dictionary];
        arc4random_buf(&DXShelfRevision, sizeof(DXShelfRevision));
        DXShelfRevision = (DXShelfRevision & 0x1fffffffffffffffULL) + 1;
    }
    // Random initial revision distinguishes a new SpringBoard lifetime.
    uint64_t revision = DXShelfRevision + 1;
    NSUInteger bank = revision & 1;
    // 发布运行在 SpringBoard 主线程的清理与通知路径上：序列化遇到异常值必须
    // 就地失败，绝不能把未捕获异常抛进主线程。
    NSData *data = nil;
    @try {
        data = [NSPropertyListSerialization dataWithPropertyList:snapshot format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    } @catch (NSException *exception) {
        NSLog(@"[TypeX][FloatingShelf] snapshot serialization exception=%@", exception.name);
        return NO;
    }
    if (!data.length || data.length > DXFloatingShelfMaxBytes) return NO;
    for (NSUInteger offset = 0; offset < data.length; offset += 8) {
        uint64_t word = 0;
        memcpy(&word, (const uint8_t *)data.bytes + offset, MIN((NSUInteger)8, data.length - offset));
        if (!DXShelfWrite(DXShelfSlot(bank, [NSString stringWithFormat:@"%lu", (unsigned long)(offset / 8)]), word)) return NO;
    }
    if (!DXShelfWrite(DXShelfSlot(bank, @"size"), data.length) ||
        !DXShelfWrite(@(DXFloatingShelfChangedName), revision)) return NO;
    DXShelfRevision = revision;
    return notify_post(DXFloatingShelfChangedName) == NOTIFY_STATUS_OK;
}
NSDictionary *DXReadFloatingShelf(void) {
    for (NSUInteger attempt = 0; attempt < 3; attempt++) {
        uint64_t revision = 0, length = 0, after = 0;
        if (!DXShelfRead(@(DXFloatingShelfChangedName), &revision) || !revision ||
            !DXShelfRead(DXShelfSlot(revision & 1, @"size"), &length) || !length || length > DXFloatingShelfMaxBytes) return nil;
        NSMutableData *data = [NSMutableData dataWithLength:(NSUInteger)length];
        for (NSUInteger offset = 0; offset < length; offset += 8) {
            uint64_t word = 0;
            if (!DXShelfRead(DXShelfSlot(revision & 1, [NSString stringWithFormat:@"%lu", (unsigned long)(offset / 8)]), &word)) return nil;
            memcpy((uint8_t *)data.mutableBytes + offset, &word, MIN((NSUInteger)8, (NSUInteger)length - offset));
        }
        if (!DXShelfRead(@(DXFloatingShelfChangedName), &after)) return nil;
        if (after != revision) continue;
        id snapshot = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:nil];
        if (!DXFloatingShelfSnapshotValid(snapshot)) return nil;
        NSMutableDictionary *result = [snapshot mutableCopy];
        result[@"revision"] = @(revision);
        return result;
    }
    return nil;
}

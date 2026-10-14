//
//  KXProbeKeyboardXCore.m
//  编译进 KeyboardXCore.dylib（Kayoko 核心 / SpringBoard 侧）。
//  作用同 KXProbeKeyboardX.m：作为该 dylib 的加载起点标记。
//

#import <Foundation/Foundation.h>
#import "KXBootTrace.h"

__attribute__((constructor(101)))
static void KXProbeKeyboardXCoreLoaded(void) {
    KXTrace("image", "KeyboardXCore.dylib loaded");
}

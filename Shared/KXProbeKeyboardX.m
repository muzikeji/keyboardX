//
//  KXProbeKeyboardX.m
//  编译进 KeyboardX.dylib（TypeX + Kayoko 键盘侧）。
//  构造函数优先级取较小值，使其先于其它构造函数执行，
//  这样 boot.log 里会先出现 "image loaded"，再出现各组件步骤。
//  若日志里连这一行都没有，说明 dylib 根本没被加载（dyld/过滤器问题）。
//

#import <Foundation/Foundation.h>
#import "KXBootTrace.h"

__attribute__((constructor(101)))
static void KXProbeKeyboardXLoaded(void) {
    KXTrace("image", "KeyboardX.dylib loaded");
}

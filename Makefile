export PACKAGE_VERSION := 1.0.6
export ARCHS := arm64 arm64e
export TARGET := iphone:clang:16.5:15.0

# 默认产出 rootless 包；CI 用矩阵额外构建 roothide。
export THEOS_PACKAGE_SCHEME ?= rootless

# keyboardX 是 Kayoko(剪贴板) 与 TypeX(键盘增强) 的合并工程。
#
# 进程模型（沿用两个上游各自验证过的划分）：
#   KeyboardX      ← TypeX 全部源码 + Kayoko Helper 全部源码   filter: com.apple.UIKit
#                    （com.apple.UIKit 已覆盖 SpringBoard，故与两个上游的加载范围一致）
#   KeyboardXCore  ← Kayoko Core 全部源码                      filter: springboard, druid, pasted
#   KeyboardXPreferences ← 两套偏好面板合并为单一 bundle
#   keyboardx_updater    ← Kayoko CLI 导入器
#
# 注意：本机为 4GB 内存且无 swap，-j4 会导致大文件（DXFloatingAppRuntime.mm、
# TypeX.xm 经 Logos 展开后）的 clang 进程被 OOM 杀死，留下 .o.tmp 残file 并使链接失败。
# 因此构建脚本必须限制并发；推荐 -j2，内存紧张时用 -j1。

# 工具链说明：Alpine clang 19 + iPhoneOS16.5.sdk 下，theos 的 HBLog.h 会把
# HBLogDebug(@"字面量") 展开成 [NSString stringWithFormat:@"字面量"]，触发 -Wformat-security。
# theos 默认无条件追加 -Werror 且排在实例 flags 之后，会盖掉实例里的 -Wno-error。
# 处理方式：(1) 已按编译器建议把 14 处 HBLogDebug(@"字面量") 改为 HBLogDebug(@"%@", @"字面量")；
#          (2) 这里关掉 theos 的 -Werror，避免不同工具链下的告警差异直接中断构建。
export GO_EASY_ON_ME = 1

INSTALL_TARGET_PROCESSES := backboardd druid pasted

SUBPROJECTS += Core
SUBPROJECTS += KeyboardX
SUBPROJECTS += Preferences
SUBPROJECTS += Updater

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

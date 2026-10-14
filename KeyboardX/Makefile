TWEAK_NAME := KeyboardX

KeyboardX_USE_MODULES := 0

# TypeX 全部源码（键盘增强）+ Kayoko Helper 全部源码（剪贴板键盘侧）
KeyboardX_FILES += $(wildcard ../TypeX/*.m)
KeyboardX_FILES += $(wildcard ../TypeX/*.mm)
KeyboardX_FILES += $(wildcard ../TypeX/*.xm)
KeyboardX_FILES += $(wildcard ../Helper/*.m)
KeyboardX_FILES += ../Shared/KXProbeKeyboardX.m
KeyboardX_FILES += $(wildcard ../Helper/*.mm)

KeyboardX_CFLAGS += -fobjc-arc
# Alpine clang 19 + iPhoneOS16.5.sdk 下 theos 的 HBLog.h 会把 HBLogDebug(@"字面量")
# 展开为 [NSString stringWithFormat:@"字面量"]，触发 -Wformat-security；上游 macOS 工具链不触发。
# 仅把该警告降级为提示，其余警告仍按 -Werror 处理。
KeyboardX_CFLAGS += -Wno-format-security
KeyboardX_CFLAGS += -I../TypeX
KeyboardX_CFLAGS += -I../Helper
KeyboardX_CFLAGS += -I../Preferences
KeyboardX_CFLAGS += -I../Shared
KeyboardX_CFLAGS += -I../Shared/Tags

# TypeX 所需 + Kayoko Helper 所需 的并集
KeyboardX_FRAMEWORKS += UIKit
KeyboardX_FRAMEWORKS += CoreGraphics
KeyboardX_FRAMEWORKS += QuartzCore
KeyboardX_FRAMEWORKS += ImageIO
KeyboardX_FRAMEWORKS += SafariServices
KeyboardX_FRAMEWORKS += PhotosUI
KeyboardX_FRAMEWORKS += UniformTypeIdentifiers
KeyboardX_FRAMEWORKS += JavaScriptCore
KeyboardX_FRAMEWORKS += AudioToolbox

KeyboardX_PRIVATE_FRAMEWORKS += AppSupport
KeyboardX_PRIVATE_FRAMEWORKS += Preferences
KeyboardX_PRIVATE_FRAMEWORKS += FrontBoardServices
KeyboardX_PRIVATE_FRAMEWORKS += SpringBoardServices

KeyboardX_LIBRARIES += substrate

# TypeX 源码使用 jbroot()/DX_ROOT_PATH_NS 做路径重定向；roothide 方案下由 libroothide 提供，
# rootless 方案下 theos 已自动追加 -lroot（见 makefiles/instance/rules.mk）。
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
KeyboardX_LIBRARIES += roothide
endif

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tweak.mk

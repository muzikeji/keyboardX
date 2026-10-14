TWEAK_NAME := KeyboardXCore

KeyboardXCore_USE_MODULES := 0

KeyboardXCore_FILES += ../Shared/KXProbeKeyboardXCore.m
KeyboardXCore_FILES += KayokoCore.m
KeyboardXCore_FILES += KayokoCoreRuntime.m
KeyboardXCore_FILES += KayokoKeyboardHostResolver.m
KeyboardXCore_FILES += KayokoSpringBoardHooks.m
KeyboardXCore_FILES += KayokoPasteTipHooks.m
KeyboardXCore_FILES += ../Helper/KayokoSwipeUpGestureRecognizer.m
KeyboardXCore_FILES += $(wildcard Manager/*.m Actions/*.m Controllers/*.m Coordinators/*.m DataSources/*.m Models/*.m Presentation/*.m Views/*.m)
KeyboardXCore_FILES += $(wildcard ../Shared/Tags/*.m)

KeyboardXCore_CFLAGS += -fobjc-arc
# Alpine clang 19 + iPhoneOS16.5.sdk 下 theos 的 HBLog.h 会把 HBLogDebug(@"字面量")
# 展开为 [NSString stringWithFormat:@"字面量"]，触发 -Wformat-security；上游 macOS 工具链不触发。
# 仅把该警告降级为提示，其余警告仍按 -Werror 处理。
KeyboardXCore_CFLAGS += -Wno-format-security
KeyboardXCore_CFLAGS += -I.
KeyboardXCore_CFLAGS += -IManager
KeyboardXCore_CFLAGS += -I../Preferences
KeyboardXCore_CFLAGS += -I../Helper
KeyboardXCore_CFLAGS += -IActions
KeyboardXCore_CFLAGS += -IControllers
KeyboardXCore_CFLAGS += -ICoordinators
KeyboardXCore_CFLAGS += -IDataSources
KeyboardXCore_CFLAGS += -IModels
KeyboardXCore_CFLAGS += -IPresentation
KeyboardXCore_CFLAGS += -IViews
KeyboardXCore_CFLAGS += -I../Shared
KeyboardXCore_CFLAGS += -I../Shared/Tags

KeyboardXCore_FRAMEWORKS += AudioToolbox
KeyboardXCore_FRAMEWORKS += AVFoundation
KeyboardXCore_FRAMEWORKS += CoreGraphics
KeyboardXCore_FRAMEWORKS += ImageIO
KeyboardXCore_FRAMEWORKS += IOKit
KeyboardXCore_FRAMEWORKS += QuartzCore
KeyboardXCore_FRAMEWORKS += Security
KeyboardXCore_FRAMEWORKS += UIKit
KeyboardXCore_PRIVATE_FRAMEWORKS += CoreServices

KeyboardXCore_LIBRARIES += sqlite3
KeyboardXCore_LIBRARIES += substrate
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
KeyboardXCore_LIBRARIES += roothide
endif

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tweak.mk

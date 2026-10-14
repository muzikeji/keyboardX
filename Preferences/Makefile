BUNDLE_NAME := KeyboardXPreferences

KeyboardXPreferences_USE_MODULES := 0

# Kayoko 侧：剪贴板偏好面板
KeyboardXPreferences_FILES += $(wildcard Controllers/*.m)
KeyboardXPreferences_FILES += $(wildcard Cells/*.m)
KeyboardXPreferences_FILES += $(wildcard Utilities/*.m)
KeyboardXPreferences_FILES += $(wildcard ../Shared/Tags/*.m)

# TypeX 侧：键盘增强偏好面板 + vendored AltList（TypeX 上游自带，编译期需要其头文件）
KeyboardXPreferences_FILES += $(wildcard ../TypeX/typexprefs/*.m)
KeyboardXPreferences_FILES += $(wildcard ../TypeX/typexprefs/*.mm)
KeyboardXPreferences_FILES += $(wildcard ../TypeX/typexprefs/AltList/*.m)
KeyboardXPreferences_FILES += ../TypeX/DXPrefsManager.m
KeyboardXPreferences_FILES += ../TypeX/DXShortcutsGenerator.m
KeyboardXPreferences_FILES += ../TypeX/DXHelper.m
KeyboardXPreferences_FILES += ../TypeX/DXAIEngine.m
KeyboardXPreferences_FILES += ../TypeX/DXJavaScriptEngine.m
KeyboardXPreferences_FILES += ../TypeX/DXPanelSystemControlsView.m
KeyboardXPreferences_FILES += ../TypeX/DXPanelPagedGridView.m

KeyboardXPreferences_CFLAGS += -fobjc-arc
# Alpine clang 19 + iPhoneOS16.5.sdk 下 theos 的 HBLog.h 会把 HBLogDebug(@"字面量")
# 展开为 [NSString stringWithFormat:@"字面量"]，触发 -Wformat-security；上游 macOS 工具链不触发。
# 仅把该警告降级为提示，其余警告仍按 -Werror 处理。
KeyboardXPreferences_CFLAGS += -Wno-format-security
KeyboardXPreferences_CFLAGS += -Wno-tautological-pointer-compare
KeyboardXPreferences_CFLAGS += -I.
KeyboardXPreferences_CFLAGS += -IControllers
KeyboardXPreferences_CFLAGS += -ICells
KeyboardXPreferences_CFLAGS += -IUtilities
KeyboardXPreferences_CFLAGS += -I../Shared
KeyboardXPreferences_CFLAGS += -I../Shared/Tags
KeyboardXPreferences_CFLAGS += -I../TypeX
KeyboardXPreferences_CFLAGS += -I../TypeX/typexprefs
KeyboardXPreferences_CFLAGS += -I../Helper
KeyboardXPreferences_CFLAGS += -DTYPEX_PACKAGE_VERSION=\"$(or $(PACKAGE_VERSION),$(THEOS_PACKAGE_BASE_VERSION))\"

# MobileCoreServices 提供 LSApplicationProxy / LSApplicationWorkspace，AltList 依赖
KeyboardXPreferences_FRAMEWORKS += MobileCoreServices
KeyboardXPreferences_FRAMEWORKS += UIKit
KeyboardXPreferences_FRAMEWORKS += CoreGraphics
KeyboardXPreferences_FRAMEWORKS += QuartzCore
KeyboardXPreferences_FRAMEWORKS += Security
KeyboardXPreferences_FRAMEWORKS += SwiftUI
KeyboardXPreferences_FRAMEWORKS += JavaScriptCore
KeyboardXPreferences_FRAMEWORKS += UniformTypeIdentifiers

KeyboardXPreferences_PRIVATE_FRAMEWORKS += FrontBoardServices
KeyboardXPreferences_PRIVATE_FRAMEWORKS += Preferences
KeyboardXPreferences_PRIVATE_FRAMEWORKS += SpringBoardServices
KeyboardXPreferences_PRIVATE_FRAMEWORKS += AppSupport

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
KeyboardXPreferences_LIBRARIES += roothide
endif

KeyboardXPreferences_INSTALL_PATH := /Library/PreferenceBundles

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

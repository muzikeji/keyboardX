ARCHS := arm64
TOOL_NAME := keyboardx_updater

keyboardx_updater_USE_MODULES := 0

keyboardx_updater_FILES += main.m
keyboardx_updater_FILES += KayokoCopyLogImporter.m
keyboardx_updater_FILES += KayokoCopyVaultImporter.m
keyboardx_updater_FILES += KayokoImportFileStager.m
keyboardx_updater_FILES += KayokoPostinstallUpdater.m
keyboardx_updater_FILES += ../Core/Manager/KayokoHistoryStore.m
keyboardx_updater_FILES += ../Core/Manager/KayokoHistoryMigrator.m
keyboardx_updater_FILES += ../Core/Manager/KayokoPasteboardItem.m
keyboardx_updater_FILES += ../Core/Manager/KayokoRichTextRepresentation.m
keyboardx_updater_FILES += ../Core/Manager/KayokoSearchCriteria.m
keyboardx_updater_FILES += ../Shared/Tags/KayokoTag.m
keyboardx_updater_FILES += ../Shared/Tags/KayokoTagStore.m

keyboardx_updater_CFLAGS += -fobjc-arc
# Alpine clang 19 + iPhoneOS16.5.sdk 下 theos 的 HBLog.h 会把 HBLogDebug(@"字面量")
# 展开为 [NSString stringWithFormat:@"字面量"]，触发 -Wformat-security；上游 macOS 工具链不触发。
# 仅把该警告降级为提示，其余警告仍按 -Werror 处理。
keyboardx_updater_CFLAGS += -Wno-format-security
keyboardx_updater_CFLAGS += -I../Core/Manager
keyboardx_updater_CFLAGS += -I../Preferences
keyboardx_updater_CFLAGS += -I../Shared/Tags

keyboardx_updater_FRAMEWORKS += CoreGraphics
keyboardx_updater_FRAMEWORKS += ImageIO
keyboardx_updater_FRAMEWORKS += Security
keyboardx_updater_FRAMEWORKS += UIKit
keyboardx_updater_LIBRARIES += sqlite3
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
keyboardx_updater_LIBRARIES += roothide
endif

keyboardx_updater_INSTALL_PATH := /usr/local/libexec
keyboardx_updater_CODESIGN_FLAGS += -Splatformize.entitlements

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tool.mk

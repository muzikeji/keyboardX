//
//  KayokoNotificationKeys.h
//  Kayoko
//
//  Created by Alexandra Aurora Göttlicher
//

#import <Foundation/Foundation.h>

static NSString *const kKayokoNotificationKeyCoreShow = @"com.muzi.kayoko.core.show";
static NSString *const kKayokoLegacyNotificationKeyCoreShow = @"dev.traurige.kayoko.core.show";
static NSString *const kKayokoNotificationKeyCoreHide = @"com.muzi.kayoko.core.hide";
static NSString *const kKayokoLegacyNotificationKeyCoreHide = @"dev.traurige.kayoko.core.hide";
static NSString *const kKayokoNotificationKeyCoreReload = @"com.muzi.kayoko.core.reload";
static NSString *const kKayokoNotificationKeyCoreCheckpointHistory = @"com.muzi.kayoko.core.checkpoint-history";
static NSString *const kKayokoNotificationKeyCorePrepareMaintenance = @"com.muzi.kayoko.core.prepare-maintenance";
static NSString *const kKayokoNotificationKeyCoreResetThumbnailMemoryCache =
    @"com.muzi.kayoko.core.reset-thumbnail-memory-cache";
static NSString *const kKayokoNotificationKeyCoreClearFavorites = @"com.muzi.kayoko.core.clear-favorites";
static NSString *const kKayokoNotificationKeyCoreClearHistory = @"com.muzi.kayoko.core.clear-history";
static NSString *const kKayokoNotificationKeyHelperPaste = @"com.muzi.kayoko.helper.paste";
static NSString *const kKayokoNotificationKeyHelperRestoreFocus = @"com.muzi.kayoko.helper.restore-focus";
static NSString *const kKayokoNotificationKeyPreferencesReload = @"com.muzi.kayoko.preferences.reload";
static NSString *const kKayokoNotificationKeyPreferencesHeightReload = @"com.muzi.kayoko.preferences.height.reload";
static NSString *const kKayokoNotificationKeyExternalImportRequiresRestart =
    @"com.muzi.kayoko.preferences.external-import-requires-restart";
static NSString *const kKayokoNotificationUserInfoKeyExternalImportSucceeded = @"succeeded";
static NSString *const kKayokoNotificationUserInfoKeyExternalImportSource = @"source";
static NSString *const kKayokoExternalImportSourceCopyLog = @"CopyLog";
static NSString *const kKayokoExternalImportSourceCopyVault = @"CopyVault";
static NSString *const kKayokoNotificationKeyPasteWillStart = @"com.muzi.kayoko.paste.willstart";
static NSString *const kKayokoNotificationKeyPasteFeedback = @"com.muzi.kayoko.paste.feedback";

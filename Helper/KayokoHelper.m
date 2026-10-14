//
//  KayokoHelper.m
//  Kayoko
//
//  Created by Alexandra Aurora Göttlicher
//

#import "KayokoHelperConfiguration.h"
#import "KayokoHelperHookInstaller.h"
#import "KayokoHelperProcessContext.h"
#import "KayokoHelperRuntime.h"
#import "KXBootTrace.h"

__attribute((constructor)) static void initialize() {
    KXTrace("kayoko-helper", "ctor-enter");
    if (KXShouldSkip("kayoko-helper")) { KXTrace("kayoko-helper", "ctor-skipped"); return; }
    KayokoHelperConfiguration *configuration = [KayokoHelperConfiguration currentConfiguration];
    KXTrace("kayoko-helper", "configuration-loaded");
    if (!configuration.isEnabled) {
        KXTrace("kayoko-helper", "disabled-by-prefs");
        return;
    }

    KayokoHelperProcessContext *context = [KayokoHelperProcessContext currentContext];
    NSUInteger helperActivationMethod = configuration.activationMethod;

    BOOL systemGestureRecognizerMode = configuration.gestureRecognizerMode == kKayokoGestureRecognizerModeSystem;
    BOOL swipeUpEnabled = (configuration.activationMethod & kActivationMethodSwipeUp) != 0;
    BOOL spotlightProcess = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Spotlight"];
    if (systemGestureRecognizerMode && !spotlightProcess) {
        helperActivationMethod &= ~kActivationMethodSwipeUp;
    }

    switch (context.kind) {
    case KayokoHelperProcessKindKeyboardExtension:
        [KayokoHelperHookInstaller
            installKeyboardExtensionHooksWithActivationMethod:helperActivationMethod
                                         spotlightSwipeUpOnly:(systemGestureRecognizerMode && swipeUpEnabled)];
        return;
    case KayokoHelperProcessKindSpringBoard:
        KXTrace("kayoko-helper", "sb-runtime-begin");
        [[KayokoHelperRuntime sharedRuntime] installSpringBoardRuntimeWithConfiguration:configuration];
        KXTrace("kayoko-helper", "sb-runtime-done");
        [KayokoHelperHookInstaller installSpringBoardActivationHooksWithActivationMethod:helperActivationMethod];
        KXTrace("kayoko-helper", "sb-hooks-done");
        return;
    case KayokoHelperProcessKindApplication:
        KXTrace("kayoko-helper", "app-hooks-begin");
        [KayokoHelperHookInstaller installApplicationHooksWithActivationMethod:helperActivationMethod];
        [[KayokoHelperRuntime sharedRuntime] installApplicationRuntimeWithConfiguration:configuration];
        KXTrace("kayoko-helper", "app-hooks-done");
        return;
    case KayokoHelperProcessKindUnsupported:
        return;
    }
}

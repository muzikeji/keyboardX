//
//  KeyboardXRootListController.m
//  KeyboardX
//

#import "KeyboardXRootListController.h"
#import <Preferences/PSSpecifier.h>

@implementation KeyboardXRootListController

- (NSArray<PSSpecifier *> *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    self.navigationItem.title = [bundle localizedStringForKey:@"KeyboardX"
                                                       value:nil
                                                       table:@"KeyboardXRoot"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 让返回按钮显示为 “KeyboardX” 而不是上一级标题
    self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
}

@end

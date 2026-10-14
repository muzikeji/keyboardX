//
//  KeyboardXAboutListController.m
//  KeyboardX
//

#import "KeyboardXAboutListController.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>

@implementation KeyboardXAboutListController

- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;

    NSMutableArray *specs = [NSMutableArray array];

    // ---- 顶部：图标 + 名称 + 版本 ----
    PSSpecifier *header = [PSSpecifier preferenceSpecifierNamed:@""
                                                          target:nil
                                                             set:nil
                                                             get:nil
                                                          detail:nil
                                                            cell:PSGroupCell
                                                            edit:nil];
    [header setProperty:NSClassFromString(@"KeyboardXHeaderCell") forKey:@"cellClass"];
    [header setProperty:@"KeyboardX" forKey:@"headerTitle"];
    [header setProperty:@"KEYBOARDX_SUBTITLE" forKey:@"headerSubtitle"];
    [header setProperty:@96 forKey:@"height"];
    [specs addObject:header];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";

    PSSpecifier *versionCell = [PSSpecifier preferenceSpecifierNamed:@""
                                                              target:nil
                                                                 set:nil
                                                                 get:nil
                                                              detail:nil
                                                                cell:PSGroupCell
                                                                edit:nil];
    [versionCell setProperty:[NSString stringWithFormat:@"版本 %@ · 由 Kayoko 与 TypeX 合并而成", version]
                     forKey:@"footerText"];
    [specs addObject:versionCell];

    // ---- 关于 ----
    [specs addObject:[PSSpecifier groupSpecifierWithName:@"关于"]];

    [specs addObject:[self developerCellTitle:@"联系作者"
                                     subtitle:@"作者：Muzi"
                                          url:@"https://github.com/muzikeji"
                                        image:@"muzikeji"]];

    [specs addObject:[self developerCellTitle:@"加入 QQ 群"
                                     subtitle:@"群号: 806146241"
                                          url:@"https://qun.qq.com/universal-share/share?ac=1&authKey=aey19ZXlzUALdRdRgvP6aZZmPV2lRIeOYZvHiP0OrTKw9ar1gOjKGX%2Bi2QGvQ62T&busi_data=eyJncm91cENvZGUiOiI4MDYxNDYyNDEiLCJ0b2tlbiI6IjMwZGNlcDB4QmZaVEZVUStOTzdkU2ZDVzdiRTJJY1cwOFIrVDFsOUM3Vmc0K05tUXBSb0d4NGhHR2hyOEFxc04iLCJ1aW4iOiI1Njc5NDUwMSJ9&data=JCmmDxJEv8-s-rZtLqjPeLaiyoe5sLjDb6s2TT6tZlO7t5JLIlH-fIFVldYGeisr181ijMizL4gTCDKGmExqBg&svctype=4&tempid=h5_group_info"
                                        image:@"qq"]];

    [specs addObject:[self developerCellTitle:@"GitHub"
                                     subtitle:@"https://github.com/muzikeji"
                                          url:@"https://github.com/muzikeji"
                                        image:@"github"]];

    [specs addObject:[self developerCellTitle:@"木子源"
                                     subtitle:@"https://muzikeji.github.io/sileo"
                                          url:@"sileo://source/https://muzikeji.github.io/sileo"
                                        image:@"muzikeji"]];

    // ---- 开源许可 ----
    [specs addObject:[PSSpecifier groupSpecifierWithName:@"开源许可"]];

    PSSpecifier *licenseFooter = [PSSpecifier preferenceSpecifierNamed:@""
                                                                target:nil
                                                                   set:nil
                                                                   get:nil
                                                                detail:nil
                                                                  cell:PSGroupCell
                                                                  edit:nil];
    [licenseFooter setProperty:
        @"KeyboardX 由两个开源项目合并而成，整体以 AGPL-3.0 发布：\n"
        @"• Kayoko —— 剪贴板管理器（作者 uz.ra，基于「乌龙版」修改），GPL-3.0\n"
        @"• TypeX —— 键盘增强插件（作者 lindo），AGPL-3.0\n"
        @"• AltList —— 应用列表控制器（作者 opa334），MIT\n"
        @"• PullOver X —— GPL-3.0\n"
        @"GPL-3.0 与 AGPL-3.0 允许合并为同一程序，合并后整体适用 AGPL-3.0。"
                     forKey:@"footerText"];
    [specs addObject:licenseFooter];

    PSSpecifier *footer = [PSSpecifier preferenceSpecifierNamed:@""
                                                         target:nil
                                                            set:nil
                                                            get:nil
                                                         detail:nil
                                                           cell:PSGroupCell
                                                           edit:nil];
    [footer setProperty:@"KeyboardX © 2025-2026 • by Muzi" forKey:@"footerText"];
    [footer setProperty:@1 forKey:@"footerAlignment"];
    [specs addObject:footer];

    _specifiers = specs;
    return _specifiers;
}

// 与 MUtool 的 developerCellTitle:subtitle:url:image: 一致
- (PSSpecifier *)developerCellTitle:(NSString *)title
                           subtitle:(NSString *)subtitle
                                url:(NSString *)url
                              image:(NSString *)image {
    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@""
                                                            target:self
                                                               set:nil
                                                               get:nil
                                                            detail:nil
                                                              cell:PSButtonCell
                                                              edit:nil];
    [specifier setProperty:title forKey:@"Title"];
    [specifier setProperty:subtitle forKey:@"Subtitle"];
    [specifier setProperty:url forKey:@"Url"];
    [specifier setProperty:image forKey:@"Image"];
    [specifier setProperty:NSClassFromString(@"KeyboardXDeveloperCell") forKey:@"cellClass"];
    [specifier setProperty:@60 forKey:@"height"];
    [specifier setProperty:@"custom_cell" forKey:@"id"];
    return specifier;
}

@end

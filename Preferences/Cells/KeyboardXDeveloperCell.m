//
//  KeyboardXDeveloperCell.m
//  KeyboardX
//
//  移植自 MUtool 的 MUtoolDeveloperCell（作者 Muzi）：
//  43pt 圆形头像 + 主标题 + 副标题 + Safari 箭头，整行可点，点击打开 specifier 的 Url。
//

#import "KeyboardXDeveloperCell.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>

#import "github.h"
#import "qq.h"
#import "muzikeji.h"

@interface KeyboardXDeveloperCell ()
@property(nonatomic, retain) UIImageView *avatarImageView;
@property(nonatomic, retain) UILabel *titleNameLabel;
@property(nonatomic, retain) UILabel *subTitleNameLabel;
@property(nonatomic, retain) UIView *tapRecognizerView;
@property(nonatomic, retain) UITapGestureRecognizer *tap;
@property(nonatomic, copy) NSString *titleName;
@property(nonatomic, copy) NSString *subTitleName;
@property(nonatomic, copy) NSString *urlString;
@property(nonatomic, copy) NSString *imageName;
@end

@implementation KeyboardXDeveloperCell

static UIImage *KeyboardXGetImageByKey(NSString *key) {
    static NSMutableDictionary *cache;
    if (!cache) cache = [NSMutableDictionary new];

    UIImage *img = cache[key];
    if (img) return img;

    NSData *data = nil;
    if ([key isEqualToString:@"github"]) {
        data = [NSData dataWithBytes:github_png length:github_png_len];
    } else if ([key isEqualToString:@"muzikeji"]) {
        data = [NSData dataWithBytes:muzikeji_png length:muzikeji_png_len];
    } else if ([key isEqualToString:@"qq"]) {
        data = [NSData dataWithBytes:qq_png length:qq_png_len];
    }

    if (data) {
        img = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
        if (img) cache[key] = img;
    }
    return img;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                    specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if (!self) return nil;

    self.titleName = specifier.properties[@"Title"];
    self.subTitleName = specifier.properties[@"Subtitle"];
    self.urlString = specifier.properties[@"Url"];
    self.imageName = specifier.properties[@"Image"];

    UILayoutGuide *margins = [self layoutMarginsGuide];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 21.5;
    self.avatarImageView.layer.borderWidth = 2;
    self.avatarImageView.layer.borderColor = [[UIColor labelColor] colorWithAlphaComponent:0.1].CGColor;
    [self addSubview:self.avatarImageView];

    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
        [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:43],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:43]
    ]];

    NSString *key = self.imageName;
    UIImageView *imageView = self.avatarImageView;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *img = KeyboardXGetImageByKey(key);
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = img;
        });
    });

    self.titleNameLabel = [[UILabel alloc] init];
    self.titleNameLabel.text = self.titleName;
    self.titleNameLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.titleNameLabel.textColor = [UIColor labelColor];
    [self addSubview:self.titleNameLabel];

    self.titleNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleNameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:12],
        [self.titleNameLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.topAnchor constant:4],
        [self.titleNameLabel.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor]
    ]];

    self.subTitleNameLabel = [[UILabel alloc] init];
    self.subTitleNameLabel.text = self.subTitleName;
    self.subTitleNameLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    self.subTitleNameLabel.textColor = [[UIColor labelColor] colorWithAlphaComponent:0.6];
    [self addSubview:self.subTitleNameLabel];

    self.subTitleNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.subTitleNameLabel.leadingAnchor constraintEqualToAnchor:self.titleNameLabel.leadingAnchor],
        [self.subTitleNameLabel.bottomAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:-4],
        [self.subTitleNameLabel.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor]
    ]];

    self.tapRecognizerView = [[UIView alloc] init];
    [self addSubview:self.tapRecognizerView];

    self.tapRecognizerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.tapRecognizerView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.tapRecognizerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.tapRecognizerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.tapRecognizerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];

    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openUserProfile)];
    [self.tapRecognizerView addGestureRecognizer:self.tap];

    UIImageView *safariIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"safari"]];
    safariIcon.tintColor = [UIColor systemGray3Color];
    safariIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.accessoryView = safariIcon;

    return self;
}

- (void)openUserProfile {
    NSURL *url = [NSURL URLWithString:self.urlString];
    if (!url) return;
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end

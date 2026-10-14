//
//  KeyboardXHeaderCell.m
//  KeyboardX
//

#import "KeyboardXHeaderCell.h"
#import <Preferences/PSSpecifier.h>

@implementation KeyboardXHeaderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                    specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if (!self) return nil;

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self setBackgroundColor:[UIColor clearColor]];
    [[self contentView] setBackgroundColor:[UIColor clearColor]];
    UILayoutGuide *margins = [self layoutMarginsGuide];

    UIImage *icon = [UIImage imageNamed:@"KeyboardXIcon" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
    [iconView setContentMode:UIViewContentModeScaleAspectFit];
    [iconView setClipsToBounds:YES];
    [[iconView layer] setCornerRadius:11];
    [[iconView layer] setBorderWidth:0.5];
    [[iconView layer] setBorderColor:[[[UIColor labelColor] colorWithAlphaComponent:0.10] CGColor]];
    [iconView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self contentView] addSubview:iconView];

    UILabel *title = [[UILabel alloc] init];
    NSString *titleKey = [specifier propertyForKey:@"headerTitle"] ?: @"KeyboardX";
    title.text = [bundle localizedStringForKey:titleKey value:nil table:@"KeyboardXRoot"];
    title.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    title.textColor = [UIColor labelColor];
    title.adjustsFontSizeToFitWidth = YES;
    title.minimumScaleFactor = 0.8;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [[self contentView] addSubview:title];

    UILabel *subtitle = [[UILabel alloc] init];
    NSString *subtitleKey = [specifier propertyForKey:@"headerSubtitle"] ?: @"";
    subtitle.text = [bundle localizedStringForKey:subtitleKey value:nil table:@"KeyboardXRoot"];
    subtitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    subtitle.textColor = [UIColor secondaryLabelColor];
    subtitle.numberOfLines = 2;
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    [[self contentView] addSubview:subtitle];

    [NSLayoutConstraint activateConstraints:@[
        [iconView.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:[self contentView].centerYAnchor],
        [iconView.widthAnchor constraintEqualToConstant:54],
        [iconView.heightAnchor constraintEqualToConstant:54],
        [title.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:13],
        [title.topAnchor constraintEqualToAnchor:iconView.topAnchor constant:4],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:margins.trailingAnchor],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2],
        [subtitle.trailingAnchor constraintLessThanOrEqualToAnchor:margins.trailingAnchor]
    ]];
    return self;
}

@end

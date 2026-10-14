#import "KayokoSliderCell.h"

#import <Preferences/PSSpecifier.h>

@implementation KayokoSliderCell {
    UISlider *_slider;
    UILabel *_titleLabel;
    UILabel *_valueLabel;
    UIView *_topSeparator;
    NSString *_formatString;
    CGFloat _titleLabelWidth;
    CGFloat _valueLabelWidth;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                    specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

    if (!self) {
        return nil;
    }

    NSNumber *labelWidthNum = [specifier propertyForKey:@"valueLabelWidth"];

    if (labelWidthNum && [labelWidthNum isKindOfClass:[NSNumber class]]) {
        _valueLabelWidth = [labelWidthNum floatValue];
    } else {
        _valueLabelWidth = 50.0;
    }

    NSNumber *titleLabelWidthNum = [specifier propertyForKey:@"titleLabelWidth"];
    _titleLabelWidth = titleLabelWidthNum ? [titleLabelWidthNum floatValue] : 88.0;

    NSString *title = [specifier name];
    if ([title isKindOfClass:[NSString class]] && [title length] > 0) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
        _titleLabel.adjustsFontForContentSizeCategory = NO;
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.text = title;
        [self.contentView addSubview:_titleLabel];
    }

    _slider = [[UISlider alloc] init];
    _slider.translatesAutoresizingMaskIntoConstraints = NO;
    [_slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:_slider];

    NSNumber *showValue = [specifier propertyForKey:@"showValue"];

    if (!showValue || [showValue boolValue]) {
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:[UIFont systemFontSize] weight:UIFontWeightRegular];
        _valueLabel.textColor = [UIColor secondaryLabelColor];
        _valueLabel.numberOfLines = 1;
        _valueLabel.lineBreakMode = NSLineBreakByClipping;
        // 点击数值可弹出输入框精确设置任意值
        _valueLabel.userInteractionEnabled = YES;
        [_valueLabel addGestureRecognizer:[[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                                      action:@selector(handleValueLabelTapped)]];
        [self.contentView addSubview:_valueLabel];
    }

    if ([[specifier propertyForKey:@"showsTopSeparator"] boolValue]) {
        _topSeparator = [[UIView alloc] init];
        _topSeparator.translatesAutoresizingMaskIntoConstraints = NO;
        _topSeparator.backgroundColor = [UIColor separatorColor];
        [self.contentView addSubview:_topSeparator];
    }

    [self _syncWithSpecifier:specifier];

    [self setupConstraints];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIFont *titleFont = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    self.textLabel.font = titleFont;
    self.textLabel.adjustsFontForContentSizeCategory = NO;
    _titleLabel.font = titleFont;
}

- (void)setupConstraints {
    UILayoutGuide *margins = self.layoutMarginsGuide;
    NSLayoutXAxisAnchor *sliderLeadingAnchor = margins.leadingAnchor;

    if (_topSeparator) {
        [NSLayoutConstraint activateConstraints:@[
            [_topSeparator.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [_topSeparator.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [_topSeparator.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_topSeparator.heightAnchor constraintEqualToConstant:1.0 / [UIScreen mainScreen].scale],
        ]];
    }

    if (_titleLabel) {
        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_titleLabel.widthAnchor constraintEqualToConstant:_titleLabelWidth],
        ]];
        sliderLeadingAnchor = _titleLabel.trailingAnchor;
    }

    if (_valueLabel) {
        [NSLayoutConstraint activateConstraints:@[
            [_valueLabel.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [_valueLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_valueLabel.widthAnchor constraintEqualToConstant:_valueLabelWidth],

            [_slider.leadingAnchor constraintEqualToAnchor:sliderLeadingAnchor constant:(_titleLabel ? 12.0 : 0.0)],
            [_slider.trailingAnchor constraintEqualToAnchor:_valueLabel.leadingAnchor constant:-12],
            [_slider.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [_slider.leadingAnchor constraintEqualToAnchor:sliderLeadingAnchor constant:(_titleLabel ? 12.0 : 0.0)],
            [_slider.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [_slider.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        ]];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:44.0],
    ]];
}

- (void)_syncWithSpecifier:(PSSpecifier *)specifier {
    if (!specifier) {
        return;
    }

    _formatString = [specifier propertyForKey:@"format"];

    if (!_formatString || ![_formatString isKindOfClass:[NSString class]]) {
        _formatString = @"%.0f";
    }

    NSNumber *minValue = [specifier propertyForKey:@"min"];
    NSNumber *maxValue = [specifier propertyForKey:@"max"];

    if (minValue) {
        _slider.minimumValue = [minValue floatValue];
    }

    if (maxValue) {
        _slider.maximumValue = [maxValue floatValue];
    }

    NSNumber *isContinuous = [specifier propertyForKey:@"isContinuous"];
    _slider.continuous = isContinuous ? [isContinuous boolValue] : YES;

    NSNumber *enabled = [specifier propertyForKey:@"enabled"];
    BOOL isEnabled = !enabled || [enabled boolValue];
    [self setKayokoControlEnabled:isEnabled];

    id value = [specifier performGetter];

    if ([value isKindOfClass:[NSNumber class]]) {
        _slider.value = [value floatValue];
    } else {
        NSNumber *defaultValue = [specifier propertyForKey:@"default"];

        if (defaultValue) {
            _slider.value = [defaultValue floatValue];
        }
    }

    [self updateValueLabel];
}

- (void)setKayokoControlEnabled:(BOOL)enabled {
    _slider.enabled = enabled;
    _titleLabel.textColor = enabled ? [UIColor labelColor] : [UIColor tertiaryLabelColor];
    _valueLabel.textColor = enabled ? [UIColor secondaryLabelColor] : [UIColor tertiaryLabelColor];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    [super setSpecifier:specifier];
    [self _syncWithSpecifier:specifier];
}

- (void)updateValueLabel {
    if (_valueLabel) {
        _valueLabel.text = [NSString stringWithFormat:_formatString, _slider.value];
    }
}

- (void)sliderValueChanged:(UISlider *)slider {
    PSSpecifier *specifier = self.specifier;

    NSNumber *isSegmented = [specifier propertyForKey:@"isSegmented"];

    if (isSegmented && [isSegmented boolValue]) {
        NSNumber *segmentCount = [specifier propertyForKey:@"segmentCount"];

        if (segmentCount && [segmentCount integerValue] > 0) {
            NSInteger segments = [segmentCount integerValue];
            CGFloat range = slider.maximumValue - slider.minimumValue;
            CGFloat step = range / (CGFloat)segments;
            CGFloat normalizedValue = (slider.value - slider.minimumValue) / step;
            CGFloat snappedValue = slider.minimumValue + (round(normalizedValue) * step);
            slider.value = snappedValue;
        }
    }

    [self updateValueLabel];

    if (specifier) {
        NSNumber *value = @(slider.value);
        [specifier performSetterWithValue:value];
    }
}

// 点击数值弹出输入框，可精确设置任意值(限定在 min~max 范围)
- (void)handleValueLabelTapped {
    if (!_slider.enabled) {
        return;
    }
    NSInteger minValue = (NSInteger)_slider.minimumValue;
    NSInteger maxValue = (NSInteger)_slider.maximumValue;
    UIViewController *controller = [[self specifier] target];
    if (![controller isKindOfClass:[UIViewController class]]) {
        return;
    }

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:[[self specifier] name]
                         message:[NSString stringWithFormat:@"%ld - %ld", (long)minValue, (long)maxValue]
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      [textField setKeyboardType:UIKeyboardTypeNumberPad];
      [textField setText:[NSString stringWithFormat:@"%ld", (long)(NSInteger)_slider.value]];
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                              __strong typeof(weakSelf) strongSelf = weakSelf;
                                              if (!strongSelf) {
                                                  return;
                                              }
                                              NSInteger entered = [[alert textFields].firstObject.text integerValue];
                                              entered = MAX(minValue, MIN(maxValue, entered));
                                              strongSelf->_slider.value = (float)entered;
                                              [strongSelf updateValueLabel];
                                              [[strongSelf specifier] performSetterWithValue:@(entered)];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [controller presentViewController:alert animated:YES completion:nil];
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];
    [self _syncWithSpecifier:specifier];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _slider.value = _slider.minimumValue;
    [self updateValueLabel];
}

@end

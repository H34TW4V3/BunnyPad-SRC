//
//  BPTheme.m
//  BunnyPad iOS 6 Edition
//

#import "BPTheme.h"

static NSString * const kBPAppThemeKey = @"appTheme_ios6";

@implementation BPTheme

+ (BPAppTheme)currentTheme {
    return (BPAppTheme)[[NSUserDefaults standardUserDefaults] integerForKey:kBPAppThemeKey];
}

+ (void)setCurrentTheme:(BPAppTheme)theme {
    [[NSUserDefaults standardUserDefaults] setInteger:theme forKey:kBPAppThemeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self applyAppearance];
}

+ (UIColor *)goldColor {
    return [UIColor colorWithRed:232.0/255.0 green:178.0/255.0 blue:62.0/255.0 alpha:1.0];
}

+ (UIColor *)backgroundColorForTheme:(BPAppTheme)theme {
    switch (theme) {
        case BPAppThemeDark:
            return [UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:22.0/255.0 alpha:1.0];
        case BPAppThemeLight:
            return [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:247.0/255.0 alpha:1.0];
        case BPAppThemeGradient:
        default:
            return [UIColor colorWithRed:24.0/255.0 green:20.0/255.0 blue:48.0/255.0 alpha:1.0];
    }
}

+ (UIColor *)textColorForTheme:(BPAppTheme)theme {
    switch (theme) {
        case BPAppThemeLight:
            return [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1.0];
        case BPAppThemeDark:
        case BPAppThemeGradient:
        default:
            return [UIColor whiteColor];
    }
}

+ (UIColor *)secondaryTextColorForTheme:(BPAppTheme)theme {
    switch (theme) {
        case BPAppThemeLight:
            return [UIColor colorWithWhite:0.4 alpha:1.0];
        case BPAppThemeDark:
        case BPAppThemeGradient:
        default:
            return [UIColor colorWithWhite:0.8 alpha:1.0];
    }
}

+ (UIColor *)cardBackgroundColorForTheme:(BPAppTheme)theme {
    switch (theme) {
        case BPAppThemeLight:
            return [UIColor colorWithWhite:1.0 alpha:0.85];
        case BPAppThemeDark:
            return [UIColor colorWithRed:32.0/255.0 green:32.0/255.0 blue:36.0/255.0 alpha:0.9];
        case BPAppThemeGradient:
        default:
            return [UIColor colorWithRed:20.0/255.0 green:15.0/255.0 blue:40.0/255.0 alpha:0.65];
    }
}

+ (UIColor *)cardBorderColorForTheme:(BPAppTheme)theme {
    switch (theme) {
        case BPAppThemeLight:
            return [UIColor colorWithWhite:0.85 alpha:1.0];
        case BPAppThemeDark:
            return [UIColor colorWithWhite:0.3 alpha:0.6];
        case BPAppThemeGradient:
        default:
            return [UIColor colorWithWhite:1.0 alpha:0.25];
    }
}

+ (UIColor *)editorBackgroundColorForTheme:(BPAppTheme)theme {
    return [self backgroundColorForTheme:theme];
}

+ (UIImage *)gradientImageWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 0.5, 1.0 };

    // Deep purple -> Midnight blue -> BunnyPad violet
    CGFloat components[] = {
        0.10, 0.06, 0.22, 1.0,
        0.05, 0.12, 0.28, 1.0,
        0.18, 0.08, 0.32, 1.0
    };

    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 3);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(size.width, size.height), 0);

    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (void)applyAppearance {
    BPAppTheme theme = [self currentTheme];
    UIColor *navBarTint = (theme == BPAppThemeLight) ? [UIColor colorWithRed:230/255.0 green:230/255.0 blue:235/255.0 alpha:1.0] : [UIColor colorWithRed:25/255.0 green:20/255.0 blue:45/255.0 alpha:1.0];

    [[UINavigationBar appearance] setTintColor:navBarTint];
    [[UIToolbar appearance] setTintColor:navBarTint];
    [[UIBarButtonItem appearance] setTintColor:[self goldColor]];
}

@end

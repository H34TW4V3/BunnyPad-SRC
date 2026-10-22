//
//  BPTheme.h
//  BunnyPad iOS 6 Edition
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BPAppTheme) {
    BPAppThemeGradient = 0,
    BPAppThemeDark     = 1,
    BPAppThemeLight    = 2
};

@interface BPTheme : NSObject

+ (BPAppTheme)currentTheme;
+ (void)setCurrentTheme:(BPAppTheme)theme;

+ (UIColor *)goldColor;
+ (UIColor *)backgroundColorForTheme:(BPAppTheme)theme;
+ (UIColor *)textColorForTheme:(BPAppTheme)theme;
+ (UIColor *)secondaryTextColorForTheme:(BPAppTheme)theme;
+ (UIColor *)cardBackgroundColorForTheme:(BPAppTheme)theme;
+ (UIColor *)cardBorderColorForTheme:(BPAppTheme)theme;
+ (UIColor *)editorBackgroundColorForTheme:(BPAppTheme)theme;

+ (UIImage *)gradientImageWithSize:(CGSize)size;
+ (void)applyAppearance;

@end

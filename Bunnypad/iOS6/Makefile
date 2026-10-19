TARGET := iphone:clang:6.1:6.0
ARCHS := armv7 armv7s

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Bunnypad

Bunnypad_FILES = main.m \
                 BPAppDelegate.m \
                 BPHomeViewController.m \
                 BPEditorViewController.m \
                 BPSettingsViewController.m \
                 BPAboutViewController.m \
                 BPNoteManager.m \
                 BPTheme.m

Bunnypad_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
Bunnypad_CFLAGS = -fobjc-arc
Bunnypad_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk

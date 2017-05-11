YORGEABBOTT53 = arm64 armv7
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DakrMusic10_MusicUI
DarkMusic10_MusicUI_FILES = Tweak.xm
DarkMusic10MusicUI_LDFLAGS += -Wl,-segalign,4000
DarkMuisc10_MUISCUI_FRAMEWORKS = UIKits

include $(THEOS)/makefiles/tweak.mk

GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Nebula
Nebula_FILES = NBLRootListController.m NBLBlacklistController.m
Nebula_INSTALL_PATH = /Library/PreferenceBundles
Nebula_FRAMEWORKS = UIKit
Nebula_PRIVATE_FRAMEWORKS = Preferences
Nebula_CFLAGS = -fobjc-arc
Nebula_LIBRARIES = colorpicker applist
Nebula_EXTRA_FRAMEWORKS += Cephei CepheiPrefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Nebula.plist$(ECHO_END)

ARCHS = armv7 arm64
TARGET = iphone:latest
GO_EASY_ON_ME = 1
FINALPACKAGE=1
DEBUG=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Nebula
Nebula_FILES = Tweak.xm
Nebula_CFLAGS = -fobjc-arc
Nebula_LIBRARIES = colorpicker applist

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += nebula
include $(THEOS_MAKE_PATH)/aggregate.mk

ARCHS = armv7
GO_EASY_ON_ME = 1
THEOS_BUILD_DIR = debs

include theos/makefiles/common.mk

TWEAK_NAME = NativeQR
NativeQR_FILES = Tweak.xm QROutputController.m QRCode.m DataMatrix.mm QR_Encode.cpp QREncoder.mm
NativeQR_FRAMEWORKS = AVFoundation CoreMedia CoreVideo QuartzCore Foundation CoreGraphics UIKit CoreImage MessageUI AddressBook AddressBookUI CoreFoundation EventKit
NativeQR_LDFLAGS = -liconv
NativeQR_OBJ_FILES = libzbar.a


include $(THEOS_MAKE_PATH)/tweak.mk

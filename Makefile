SDKVERSION=5.0

include theos/makefiles/common.mk

TWEAK_NAME = UnFolderX
UnFolderX_FILES = Tweak.xm
UnFolderX_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

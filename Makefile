TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = successorcli

successorcli_FILES = $(wildcard Sources/SuccessorCLI/*.swift)
successorcli_PRIVATE_FRAMEWORKS = DiskImages2 SpringBoardServices
successorcli_CODESIGN_FLAGS = -Sentitlements.plist
successorcli_INSTALL_PATH = /usr/sbin
successorcli_SWIFTFLAGS = -suppress-warnings -ISources/SuccessorCLIBridged # look for the module in the include directory
include $(THEOS_MAKE_PATH)/tool.mk

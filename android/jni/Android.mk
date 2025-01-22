# Copyright (C) 2012 Corona Labs Inc.
#

# TARGET_PLATFORM := android-8

LOCAL_PATH := $(call my-dir)

ifeq ($(OS),Windows_NT)
	CORONA_ROOT := C:\PROGRA~2\CORONA~1\Corona\Native
else
	CORONA := /Applications/Corona-3714
	CORONA_ROOT := $(CORONA)/Native
endif

LUA_API_DIR := $(CORONA_ROOT)/Corona/shared/include/lua
LUA_API_CORONA := $(CORONA_ROOT)/Corona/shared/include/Corona

PLUGIN_DIR := ../..

SRC_DIR := $(PLUGIN_DIR)/shared
SRC_DIR := $(PLUGIN_DIR)/shared/spine
CEU_DIR := $(PLUGIN_DIR)/../solar2d_native_utils
CEU_SRC := $(CEU_DIR)/utils

# -----------------------------------------------------------------------------

include $(CLEAR_VARS)
LOCAL_MODULE := liblua
LOCAL_SRC_FILES := ../corona-libs/jni/$(TARGET_ARCH_ABI)/liblua.so
LOCAL_EXPORT_C_INCLUDES := $(LUA_API_DIR)
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := libcorona
LOCAL_SRC_FILES := ../corona-libs/jni/$(TARGET_ARCH_ABI)/libcorona.so
LOCAL_EXPORT_C_INCLUDES := $(LUA_API_CORONA)
include $(PREBUILT_SHARED_LIBRARY)

# -----------------------------------------------------------------------------


include $(CLEAR_VARS)
LOCAL_MODULE := libplugin.spine

SHARED_SRC := $(wildcard $(LOCAL_PATH)/../../shared/*.cpp)
SPINE_SRC := $(wildcard $(LOCAL_PATH)/../../shared/spine/*.cpp)

LOCAL_SRC_FILES := $(SHARED_SRC:$(LOCAL_PATH)/%=%) \
                   $(SPINE_SRC:$(LOCAL_PATH)/%=%)

# Add include directories
LOCAL_C_INCLUDES := \
    $(LOCAL_PATH)/../../shared \
    $(LOCAL_PATH)/../../shared/spine

LOCAL_LDLIBS := -llog

LOCAL_CFLAGS := \
	-DANDROID_NDK \
	-DNDEBUG \
	-D_REENTRANT \
	-DRtt_ANDROID_ENV

LOCAL_LDLIBS := -llog

LOCAL_SHARED_LIBRARIES := \
	liblua libcorona

ifeq ($(TARGET_ARCH),arm)
LOCAL_CFLAGS += -D_ARM_ASSEM_ -D_M_ARM
endif

ifeq ($(TARGET_ARCH),armeabi-v7a)
LOCAL_CFLAGS += -DHAVENEON=1
endif

# LOCAL_CFLAGS += -mfloat-abi=softfp -mfpu=neon -march=armv7 -mthumb
LOCAL_CPPFLAGS += -std=c++17
LOCAL_CPP_FEATURES += exceptions

# Arm vs Thumb.
LOCAL_ARM_MODE := arm
LOCAL_ARM_NEON := true
include $(BUILD_SHARED_LIBRARY)

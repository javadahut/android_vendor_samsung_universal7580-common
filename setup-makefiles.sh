#!/bin/bash
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


VENDOR=samsung
DEVICE_COMMON=universal7580-common

# Load extractutils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$MY_DIR"/../../..

HELPER="$LINEAGE_ROOT"/vendor/lineage/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Initialize the helper
setup_vendor "$DEVICE_COMMON" "$VENDOR" "$LINEAGE_ROOT" true

# Copyright headers and guards
write_headers "a3xelte a5xelte a7xelte gvwifi gvlte j7elte s5neolte"

# The standard blobs
write_makefiles "$MY_DIR"/proprietary-files.txt true

# The BSP blobs - we put a conditional in case the BSP
# is actually being built
printf '\n%s\n' 'ifeq ($(WITH_EXYNOS_BSP),)' >> "$PRODUCTMK"
printf '\n%s\n' 'ifeq ($(WITH_EXYNOS_BSP),)' >> "$ANDROIDMK"

write_makefiles "$MY_DIR"/proprietary-files-bsp.txt

printf '%s\n' 'endif' >> "$PRODUCTMK"
printf '%s\n' 'endif' >> "$ANDROIDMK"

###################################################################################################
# CUSTOM PART START                                                                               #
###################################################################################################
OUTDIR=vendor/$VENDOR/$DEVICE_COMMON
(cat << EOF) >> $LINEAGE_ROOT/$OUTDIR/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := libGLES_mali
LOCAL_MODULE_OWNER := samsung
LOCAL_SRC_FILES := proprietary/vendor/lib/egl/libGLES_mali.so
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/egl

SYMLINKS := \$(TARGET_OUT)/vendor
\$(SYMLINKS):
	@echo "Symlink: vulkan.exynos5.so"
	@mkdir -p \$@/lib/hw
	\$(hide) ln -sf ../egl/libGLES_mali.so \$@/lib/hw/vulkan.exynos5.so
	@echo "Symlink: libOpenCL.so"
	\$(hide) ln -sf egl/libGLES_mali.so \$@/lib/libOpenCL.so
	@echo "Symlink: libOpenCL.so.1"
	\$(hide) ln -sf egl/libGLES_mali.so \$@/lib/libOpenCL.so.1
	@echo "Symlink: libOpenCL.so.1.1"
	\$(hide) ln -sf egl/libGLES_mali.so \$@/lib/libOpenCL.so.1.1

ALL_MODULES.\$(LOCAL_MODULE).INSTALLED := \\
	\$(ALL_MODULES.\$(LOCAL_MODULE).INSTALLED) \$(SYMLINKS)

include \$(BUILD_PREBUILT)

EOF

(cat << EOF) >> $LINEAGE_ROOT/$OUTDIR/$DEVICE_COMMON-vendor.mk

# Create Mali links for Vulkan and OpenCL
PRODUCT_PACKAGES += libGLES_mali
EOF
###################################################################################################
# CUSTOM PART END                                                                                 #
###################################################################################################

# Done
write_footers

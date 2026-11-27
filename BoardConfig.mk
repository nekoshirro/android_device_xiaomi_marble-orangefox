#
# Copyright (C) 2022-2026 The LineageOS Project
# Copyright (C) 2024-2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/marble

# SDK
BOARD_SYSTEMSDK_VERSIONS := 31

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a-branchprot
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := kryo385

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a75

# Assert
TARGET_OTA_ASSERT_DEVICE := marble,marblein

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := taro
TARGET_NO_BOOTLOADER := false
TARGET_USES_UEFI := true
TARGET_USES_REMOTEPROC := true

# Kernel / Ramdisk
# marble uses boot header v4 with a dedicated recovery_{a,b} partition.
# Excluding the kernel from recovery.img ensures the bootloader always pairs
# this recovery ramdisk with the installed ROM's boot_{a,b} kernel and
# vendor_boot_{a,b} DTB/DTBO, supporting both GKI 5.10 and GKI 6.6 ROMs.
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
BOARD_KERNEL_IMAGE_NAME := kernel
BOARD_RAMDISK_USE_LZ4 := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/$(BOARD_KERNEL_IMAGE_NAME)

# Partition sizes and filesystems
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
BOARD_FLASH_BLOCK_SIZE := 262144 # (4096 * 64)

BOARD_BOOTIMAGE_PARTITION_SIZE := 0x0C000000
BOARD_KERNEL-GKI_BOOTIMAGE_PARTITION_SIZE := $(BOARD_BOOTIMAGE_PARTITION_SIZE)
BOARD_DTBOIMG_PARTITION_SIZE := 0x01800000
BOARD_METADATAIMAGE_PARTITION_SIZE := 16777216
BOARD_PERSISTIMAGE_PARTITION_SIZE := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x06400000
BOARD_USERDATAIMAGE_PARTITION_SIZE := 15032385536
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 0x06000000

# Dynamic partitions (includes system_dlkm for 6.6 ROMs alongside 5.10 partitions)
BOARD_SUPER_PARTITION_SIZE := 9663676416 # 0x240000000 (9216 MiB hardware super)
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 9659482112 # BOARD_SUPER_PARTITION_SIZE - 4MiB
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    odm \
    product \
    system \
    system_dlkm \
    system_ext \
    vendor \
    vendor_dlkm

BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PERSISTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4

BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_USES_VENDOR_DLKMIMAGE := true

TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true

# Build rules compatibility
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_NINJA_USES_ENV_VARS += RTIC_MPGEN SDCLANG_AE_CONFIG SDCLANG_CONFIG SDCLANG_SA_ENABLE
BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true
BUILD_BROKEN_USES_BUILD_HOST_EXECUTABLE := true
BUILD_BROKEN_USES_BUILD_HOST_SHARED_LIBRARY := true
BUILD_BROKEN_USES_BUILD_HOST_STATIC_LIBRARY := true

# AVB
BOARD_AVB_ENABLE := true
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# Encryption / FBE
BOARD_USES_METADATA_PARTITION := true
BOARD_USES_QCOM_FBE_DECRYPTION := true
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Recovery fstab
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# Recovery shared libraries and tools required by QTI crypto, display, and vibrator HALs
TARGET_RECOVERY_DEVICE_MODULES += \
    android.hardware.security.keymint-V4-ndk \
    android.hardware.security.rkp-V3-ndk \
    android.hardware.security.secureclock-V1-ndk \
    android.hardware.security.sharedsecret-V1-ndk \
    android.hardware.vibrator-V2-ndk \
    android.hidl.allocator@1.0 \
    android.hidl.memory@1.0 \
    android.hidl.memory.token@1.0 \
    debuggerd \
    libdebuggerd_client \
    libdmabufheap \
    libexpat \
    libhidlmemory \
    libion \
    libnetutils \
    strace \
    vendor.display.config@1.0 \
    vendor.display.config@2.0

RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.keymint-V4-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.rkp-V3-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.secureclock-V1-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.sharedsecret-V1-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.vibrator-V2-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hidl.allocator@1.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hidl.memory@1.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hidl.memory.token@1.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libdebuggerd_client.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libdmabufheap.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libexpat.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libhidlmemory.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libnetutils.so \
    $(TARGET_OUT_SYSTEM_EXT_SHARED_LIBRARIES)/vendor.display.config@1.0.so \
    $(TARGET_OUT_SYSTEM_EXT_SHARED_LIBRARIES)/vendor.display.config@2.0.so

RECOVERY_BINARY_SOURCE_FILES += \
    $(TARGET_OUT_EXECUTABLES)/debuggerd \
    $(TARGET_OUT_EXECUTABLES)/strace

# Display, Brightness & UI
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TW_THEME := portrait_hdpi
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_DEFAULT_BRIGHTNESS := 420
TW_MAX_BRIGHTNESS := 4095
TW_FRAMERATE := 120
TW_NO_SCREEN_BLANK := true

# Battery & Thermal
# Read battery state directly from sysfs after ADSP boots; avoids HIDL/AIDL
# health HAL mismatches across 5.10 and 6.6 ROMs.
TW_USE_LEGACY_BATTERY_SERVICES := true
TW_CUSTOM_CPU_TEMP_PATH := "/sys/devices/virtual/thermal/thermal_zone34/temp"

# Haptics / Vibrator (QTI open-source AIDL IVibrator/default)
TW_SUPPORT_INPUT_AIDL_HAPTICS := true
TW_SUPPORT_INPUT_AIDL_HAPTICS_FIX_OFF := true
TW_SUPPORT_INPUT_AIDL_HAPTICS_FQNAME := "IVibrator/default"

# RTC & Recovery features
TARGET_RECOVERY_QCOM_RTC_FIX := true
TW_QCOM_ATS_OFFSET := 1666528204500
TW_EXCLUDE_APEX := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_EXTRA_LANGUAGES := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_RESETPROP := true
TW_NO_EXFAT_FUSE := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
TW_OVERRIDE_SYSTEM_PROPS := \
    "ro.build.fingerprint=ro.vendor.build.fingerprint;ro.build.version.incremental"

# Dynamic kernel module loading for BOTH 5.10 and 6.6 ROMs.
# OF_LOAD_ROM_MODULES requires a dangling lib/modules/modules.load.recovery
# symlink in the recovery ramdisk (created via BOARD_RECOVERY_IMAGE_PREPARE)
# so the ROM's first-stage init falls back to normal-boot modules.load instead
# of rebooting on cross-kernel mismatches, while Recovery reads the ROM's
# modules.load.recovery from vendor_boot and merges it with
# TW_LOAD_VENDOR_MODULES below across vendor_dlkm, system_dlkm, and /lib/modules.
OF_LOAD_ROM_MODULES := 1
BOARD_RECOVERY_IMAGE_PREPARE += mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/lib/modules; ln -sf /nonexistent $(TARGET_RECOVERY_ROOT_OUT)/lib/modules/modules.load.recovery;
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_LOAD_VENDOR_MODULES := "adsp_loader_dlkm.ko rproc_qcom_common.ko q6_dlkm.ko q6_notifier_dlkm.ko q6_pdr_dlkm.ko qcom_q6v5.ko qcom_q6v5_pas.ko mdt_loader.ko qcom_pil_info.ko qcom_smd.ko qmi_helpers.ko pdr_interface.ko qcom_sysmon.ko qcom_glink.ko qcom_glink_smem.ko qti_pmic_glink.ko ucsi_qti_glink.ko qti_battery_charger.ko goodix_core.ko goodix_ts.ko xiaomi_touch.ko panel_event_notifier.ko leds-qti-flash.ko qcom-hv-haptics.ko leds-qpnp-vibrator-ldo.ko pm8941-pwrkey.ko qcom-pon.ko qseecom_dlkm.ko smcinvoke_dlkm.ko qce50_dlkm.ko spcom.ko spss_utils.ko qcom_ice.ko ufshcd-crypto-qti.ko hwmon.ko cnss_prealloc.ko cnss_utils.ko cnss_nl.ko mi_cnss_statistic.ko cnss_plat_ipc_qmi_svc.ko wlan_firmware_service.ko cnss2.ko qca_cld3_qca6490.ko"

# Debug / Logging
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true

# OrangeFox build configuration (included here so OF_* vars are visible to
# vendor/recovery/orangefox_soong_config.mk and bootable/recovery/orangefox.mk)
-include $(DEVICE_PATH)/fox_marble.mk

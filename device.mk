#
# Copyright (C) 2022-2026 The LineageOS Project
# Copyright (C) 2024-2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Common AOSP configuration
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Emulated storage with project quotas and casefolding (no sdcardfs)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# GSI verified boot keys
$(call inherit-product, $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk)

# Virtual A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# Platform
PRODUCT_PLATFORM := taro
QCOM_BOARD_PLATFORMS += $(PRODUCT_PLATFORM)
TARGET_BOARD_PLATFORM := $(PRODUCT_PLATFORM)
TARGET_BOOTLOADER_BOARD_NAME := $(TARGET_BOARD_PLATFORM)

# Build relaxations for prebuilt recovery blobs
BUILD_BROKEN_DUP_RULES := true
RELAX_USES_LIBRARY_CHECK := true

# Recovery-only build uses a 0-byte kernel placeholder (dedicated recovery
# partition boots on the installed 5.10 or 6.6 ROM kernel from boot_{a,b}).
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# A/B updater
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS ?= \
    boot \
    dtbo \
    odm \
    product \
    recovery \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# A/B & Boot Control HAL
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl-qti \
    android.hardware.boot@1.2-impl-qti.recovery \
    android.hardware.boot@1.2-service \
    update_engine \
    update_engine_client \
    update_engine_sideload \
    update_verifier

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# F2FS utilities and userdata checkpoint
PRODUCT_PACKAGES += \
    check_f2fs \
    checkpoint_gc \
    f2fs_io \
    sg_write_buffer

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true

# Qualcomm FBE decryption
PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe

# GRF / Vendor API freeze level (Android 12/13 launch)
BOARD_SHIPPING_API_LEVEL := 31
PRODUCT_SHIPPING_API_LEVEL := 31
PRODUCT_TARGET_VNDK_VERSION := 31

# Compile recovery without MSM kernel headers
TARGET_HAS_GENERIC_KERNEL_HEADERS := true

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

# UFS BSG framework for librecovery_updater
SOONG_CONFIG_NAMESPACES += ufsbsg
SOONG_CONFIG_ufsbsg += ufsframework
SOONG_CONFIG_ufsbsg_ufsframework := bsg

# OEM OTA certificates
PRODUCT_EXTRA_RECOVERY_KEYS += \
    $(DEVICE_PATH)/security/otacert

# System AVB
BOARD_AVB_VBMETA_SYSTEM := system
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

# FUSE passthrough
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.fuse.passthrough.enable=true

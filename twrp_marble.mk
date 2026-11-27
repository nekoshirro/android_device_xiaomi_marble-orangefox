#
# Copyright (C) 2022-2026 The LineageOS Project
# Copyright (C) 2024-2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Release name
PRODUCT_RELEASE_NAME := marble

# Device path
DEVICE_PATH := device/xiaomi/$(PRODUCT_RELEASE_NAME)

# Inherit common TWRP/OrangeFox product configuration
$(call inherit-product, vendor/twrp/config/common.mk)

# Inherit device hardware configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# Device identifiers
PRODUCT_DEVICE := $(PRODUCT_RELEASE_NAME)
PRODUCT_NAME := twrp_$(PRODUCT_RELEASE_NAME)
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := Redmi Note 12 Turbo
PRODUCT_MANUFACTURER := Xiaomi

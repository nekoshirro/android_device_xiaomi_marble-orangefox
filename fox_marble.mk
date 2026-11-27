#
# Copyright (C) 2024-2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Dedicated recovery partition on Virtual A/B device
FOX_VIRTUAL_AB_DEVICE := 1
OF_AB_DEVICE_WITH_RECOVERY_PARTITION := 1
OF_RECOVERY_AB_FULL_REFLASH_RAMDISK := 1

# OrangeFox core behavior
FOX_VANILLA_BUILD := 1
TARGET_DEVICE_ALT := marble,marblein
FOX_RECOVERY_INSTALL_PARTITION := /dev/block/by-name/recovery
FOX_RECOVERY_SYSTEM_PARTITION := /dev/block/mapper/system
FOX_RECOVERY_VENDOR_PARTITION := /dev/block/mapper/vendor
FOX_DELETE_AROMAFM := 1
FOX_DELETE_INITD_ADDON := 1
FOX_ENABLE_APP_MANAGER := 1
FOX_MOVE_MAGISK_INSTALLER_TO_RAMDISK := 1
FOX_SETTINGS_ROOT_DIRECTORY := /persist/OFRP
FOX_ALLOW_EARLY_SETTINGS_LOAD := 1
FOX_MISCELLANEOUS_ROOT_DIRECTORY := /sdcard

# Shell and archive binaries
FOX_REPLACE_TOOLBOX_GETPROP := 1
FOX_USE_BASH_SHELL := 1
FOX_ASH_IS_BASH := 1
FOX_USE_NANO_EDITOR := 1
FOX_USE_SED_BINARY := 1
FOX_USE_TAR_BINARY := 1
FOX_USE_XZ_UTILS := 1

# Display & GUI geometry (1080x2400 AMOLED with center punch-hole)
OF_SCREEN_H := 2400
OF_STATUS_H := 100
OF_STATUS_INDENT_LEFT := 48
OF_STATUS_INDENT_RIGHT := 48
OF_HIDE_NOTCH := 1
OF_CLOCK_POS := 1
OF_ALLOW_DISABLE_NAVBAR := 1
OF_OPTIONS_LIST_NUM := 9

# Default timezone ((UTC +7) Bangkok, Hanoi, Jakarta) matching OrangeFox settings.xml
OF_DEFAULT_TIMEZONE := THAIST-7;THAIDT

# Flashlight (PM8350C flash LED channels 1 & 4 controlled via torch_0 + switch_0)
OF_USE_GREEN_LED := 0
OF_FLASHLIGHT_ENABLE := 1
OF_FL_PATH1 := /sys/class/leds/led:torch_0
OF_FL_PATH2 := /sys/class/leds/led:switch_0

# Battery (sysfs fallback for consistent 5.10 + 6.6 readings)
OF_USE_LEGACY_BATTERY_SERVICES := 1

# Haptics (paired with TW_SUPPORT_INPUT_AIDL_HAPTICS := true in BoardConfig.mk;
# aligns with upstream OrangeFox/device/mondrian and is ignored cleanly on
# fox_16.0 builds that do not consume OF_ENABLE_HAPTICS)
OF_ENABLE_HAPTICS := 1

# WLAN & SoftAP (QCA6490)
# Enabled by default; ignored cleanly on no-WLAN fox_16.0 manifests and
# activated automatically when built with OrangeFox WLAN sources.
OF_ENABLE_WLAN ?= 1
OF_WLAN_AP ?= 1

# Storage, backups & partition tools
OF_QUICK_BACKUP_LIST := /boot;/dtbo;/data;
OF_SKIP_MULTIUSER_FOLDERS_BACKUP := 1
OF_ENABLE_USB_STORAGE := 1
OF_ENABLE_ALL_PARTITION_TOOLS := 1
OF_IGNORE_LOGICAL_MOUNT_ERRORS := 1
OF_BIND_MOUNT_SDCARD_ON_FORMAT := 1
OF_FORCE_CASEFOLDING := 1
OF_DISABLE_OTA_MENU := 1
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1

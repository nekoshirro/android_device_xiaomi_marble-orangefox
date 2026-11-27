#
# Copyright (C) 2024-2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

FDEVICE="marble"

fox_get_target_device() {
    local chkdev
    chkdev=$(echo "$BASH_SOURCE" | grep -w "$FDEVICE")
    if [ -n "$chkdev" ]; then
        FOX_BUILD_DEVICE="$FDEVICE"
    else
        chkdev=$(set | grep BASH_ARGV | grep -w "$FDEVICE")
        [ -n "$chkdev" ] && FOX_BUILD_DEVICE="$FDEVICE"
    fi
}

if [ -z "$1" ] && [ -z "$FOX_BUILD_DEVICE" ]; then
    fox_get_target_device
fi

if [ "$1" = "$FDEVICE" ] || [ "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
    export LC_ALL="C.UTF-8"
    export ALLOW_MISSING_DEPENDENCIES=true
    export FOX_AB_DEVICE=1
    export FOX_VIRTUAL_AB_DEVICE=1
    export FOX_VANILLA_BUILD=1
    export TARGET_DEVICE_ALT="marble,marblein"
    export FOX_RECOVERY_INSTALL_PARTITION="/dev/block/by-name/recovery"
    export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
    export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"
    export FOX_DELETE_AROMAFM=1
    export FOX_DELETE_INITD_ADDON=1
    export FOX_ENABLE_APP_MANAGER=1
    export FOX_MOVE_MAGISK_INSTALLER_TO_RAMDISK=1
    export FOX_SETTINGS_ROOT_DIRECTORY="/persist/OFRP"
    export FOX_ALLOW_EARLY_SETTINGS_LOAD=1
    export FOX_MISCELLANEOUS_ROOT_DIRECTORY="/sdcard"
    export FOX_REPLACE_TOOLBOX_GETPROP=1
    export FOX_USE_BASH_SHELL=1
    export FOX_ASH_IS_BASH=1
    export FOX_USE_NANO_EDITOR=1
    export FOX_USE_SED_BINARY=1
    export FOX_USE_TAR_BINARY=1
    export FOX_USE_XZ_UTILS=1
    export OF_USE_GREEN_LED=0
    export OF_ALLOW_DISABLE_NAVBAR=1
    export OF_DEFAULT_TIMEZONE="THAIST-7;THAIDT"
    export OF_ENABLE_WLAN="${OF_ENABLE_WLAN:-1}"
    export OF_WLAN_AP="${OF_WLAN_AP:-1}"

    if [ -n "$FOX_BUILD_LOG_FILE" ] && [ -f "$FOX_BUILD_LOG_FILE" ]; then
        export | grep "FOX" >> "$FOX_BUILD_LOG_FILE"
        export | grep "OF_" >> "$FOX_BUILD_LOG_FILE"
        export | grep "TARGET_" >> "$FOX_BUILD_LOG_FILE"
        export | grep "TW_" >> "$FOX_BUILD_LOG_FILE"
    fi
else
    if [ -z "$FOX_BUILD_DEVICE" ] && [ -z "$BASH_SOURCE" ]; then
        echo "I: This script requires bash. Not processing $FDEVICE $(basename "$0")"
    fi
fi

#!/system/bin/sh
#
# Post-recovery-boot hook for Redmi Note 12 Turbo (marble).
# Ensures Goodix GT9916S touch (goodix_ts on 6.6, goodix_core on 5.10),
# PM8350C flashlight (leds-qti-flash), and OLED backlight are operational.
#

LOGF=/tmp/recovery.log
DLKM_MNT=/tmp/fox_vendor_dlkm
DLKM_MOUNTED=0

mount_vendor_dlkm() {
    [ "$DLKM_MOUNTED" -eq 1 ] && return 0
    if [ -d /vendor_dlkm/lib/modules ] && [ -n "$(ls -A /vendor_dlkm/lib/modules 2>/dev/null)" ]; then
        return 0
    fi

    mkdir -p "$DLKM_MNT" 2>/dev/null
    slot=$(getprop ro.boot.slot_suffix 2>/dev/null)
    for dev in \
        "/dev/block/mapper/vendor_dlkm${slot}" \
        "/dev/block/mapper/vendor_dlkm"; do
        if [ -b "$dev" ] && mount -o ro "$dev" "$DLKM_MNT" 2>/dev/null; then
            DLKM_MOUNTED=1
            return 0
        fi
    done

    if mount /vendor_dlkm 2>/dev/null; then
        DLKM_MOUNTED=2
        return 0
    fi
    return 1
}

umount_vendor_dlkm() {
    if [ "$DLKM_MOUNTED" -eq 1 ]; then
        umount "$DLKM_MNT" 2>/dev/null
        rmdir "$DLKM_MNT" 2>/dev/null
        DLKM_MOUNTED=0
    elif [ "$DLKM_MOUNTED" -eq 2 ]; then
        umount /vendor_dlkm 2>/dev/null
        DLKM_MOUNTED=0
    fi
}

find_rom_module() {
    local ko_file="${1}.ko"
    local kver
    kver=$(uname -r 2>/dev/null)

    for base in \
        "/lib/modules/${kver}" \
        "/lib/modules" \
        "/vendor_dlkm/lib/modules/${kver}" \
        "/vendor_dlkm/lib/modules" \
        "${DLKM_MNT}/lib/modules/${kver}" \
        "${DLKM_MNT}/lib/modules" \
        "/vendor/lib/modules/${kver}" \
        "/vendor/lib/modules"; do
        [ -n "$base" ] || continue
        if [ -f "${base}/${ko_file}" ]; then
            echo "${base}/${ko_file}"
            return 0
        fi
    done

    for base in /lib/modules /vendor_dlkm/lib/modules "${DLKM_MNT}/lib/modules"; do
        for candidate in "${base}"/*/"${ko_file}"; do
            if [ -f "$candidate" ]; then
                echo "$candidate"
                return 0
            fi
        done
    done
    return 1
}

load_rom_module() {
    local mod_name="$1"
    local ko=""

    ko=$(find_rom_module "$mod_name")
    if [ -z "$ko" ]; then
        mount_vendor_dlkm
        ko=$(find_rom_module "$mod_name")
    fi

    if [ -n "$ko" ]; then
        if insmod "$ko" 2>/dev/null; then
            echo "I:postrecoveryboot: loaded ${ko}" >> "$LOGF"
            return 0
        fi
    fi
    return 1
}

reload_goodix() {
    # Locate the replacement module BEFORE unloading so a failed mount can never
    # leave the touch driver unloaded with no replacement.
    local ko=""
    local target_mod=""

    mount_vendor_dlkm
    for mod in goodix_ts goodix_core; do
        ko=$(find_rom_module "$mod")
        if [ -n "$ko" ]; then
            target_mod="$mod"
            break
        fi
    done

    if [ -z "$ko" ]; then
        echo "W:postrecoveryboot: no Goodix .ko found; skipping reload" >> "$LOGF"
        return 1
    fi

    rmmod goodix_ts 2>/dev/null
    rmmod goodix_core 2>/dev/null
    if insmod "$ko" 2>/dev/null; then
        echo "I:postrecoveryboot: reloaded ${target_mod} from ${ko}" >> "$LOGF"
        return 0
    fi
    echo "W:postrecoveryboot: failed to insmod ${ko}" >> "$LOGF"
    return 1
}

# 1. Recover Goodix touch if it failed initial probe or got stuck suspended
# after a recovery restart (IRQ left disabled).
if [ ! -d /proc/goodix_ts ] && [ ! -d /sys/devices/platform/goodix_ts.0 ]; then
    reload_goodix
else
    for f in /sys/devices/platform/goodix_ts*/irq_info; do
        [ -r "$f" ] || continue
        if grep -q "state:disabled" "$f" 2>/dev/null; then
            echo "I:postrecoveryboot: Goodix IRQ disabled, re-probing touch" >> "$LOGF"
            reload_goodix
        fi
        break
    done
fi

# 2. Ensure PM8350C flashlight driver is loaded on modular 6.6 kernels
if [ ! -e /sys/class/leds/led:torch_0/brightness ]; then
    load_rom_module leds-qti-flash
fi

# 3. Ensure OLED backlight is not left at 0 after early DRM bring-up
BL=/sys/class/backlight/panel0-backlight/brightness
if [ -r "$BL" ] && [ -w "$BL" ]; then
    cur_bl=$(cat "$BL" 2>/dev/null)
    if [ "${cur_bl:-0}" -eq 0 ] 2>/dev/null; then
        echo 420 > "$BL" 2>/dev/null
    fi
fi

umount_vendor_dlkm
exit 0

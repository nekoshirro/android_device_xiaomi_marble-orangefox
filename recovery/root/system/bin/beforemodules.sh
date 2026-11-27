#!/system/bin/sh
#
# Pre-module loader hook for Redmi Note 12 Turbo (marble).
# Runs before KernelModuleLoader::Load_Vendor_Modules() on both 5.10 and 6.6 ROMs.
#

LOGF=/tmp/recovery.log
KVER=$(uname -r 2>/dev/null)
echo "I:beforemodules: running on kernel ${KVER:-unknown}" >> "$LOGF"

# If first-stage init loaded Goodix touch before firmware_directories were
# ready, the probe can stall without creating a touch device node. Unload the
# unprobed module so OF_LOAD_ROM_MODULES / Modprobe cleanly re-probes it.
goodix_probed() {
    [ -d /sys/devices/platform/goodix_ts.0 ] || [ -d /proc/goodix_ts ]
}

for mod in goodix_ts goodix_core; do
    if grep -q "^${mod} " /proc/modules 2>/dev/null && ! goodix_probed; then
        if rmmod "$mod" 2>/dev/null; then
            echo "I:beforemodules: unloaded unprobed ${mod} for clean reload" >> "$LOGF"
        else
            echo "W:beforemodules: failed to unload ${mod}" >> "$LOGF"
        fi
    fi
done

exit 0

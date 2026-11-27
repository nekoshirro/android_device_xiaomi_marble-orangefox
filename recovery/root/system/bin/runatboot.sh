#!/system/bin/sh
#
# Device identity and Qualcomm RTC time recovery hook for Redmi Note 12 Turbo (marble).
#

LOGF=/tmp/recovery.log

[ -w /config/usb_gadget/g1/strings/0x409/product ] && \
    echo "Redmi Note 12 Turbo" > /config/usb_gadget/g1/strings/0x409/product
resetprop "ro.product.brand" "Redmi"
resetprop "ro.product.model" "Redmi Note 12 Turbo"
resetprop "ro.product.marketname" "Redmi Note 12 Turbo"
resetprop "ro.orangefox.device_model" "Redmi Note 12 Turbo"
echo "I:unified-script: configured Redmi Note 12 Turbo identity" >> "$LOGF"

read_ats_sec() {
    local file="$1"
    local bytes awk_bin
    bytes=$(head -c 8 "$file" 2>/dev/null | od -An -t u1 2>/dev/null) || \
        bytes=$(head -c 8 "$file" 2>/dev/null | busybox od -An -t u1 2>/dev/null) || return 1
    if command -v awk >/dev/null 2>&1; then
        awk_bin="awk"
    elif command -v busybox >/dev/null 2>&1; then
        awk_bin="busybox awk"
    else
        return 1
    fi
    echo "$bytes" | $awk_bin '{
        if (NF < 8) exit 1
        ms = $1 + $2*256 + $3*65536 + $4*16777216 + $5*4294967296 + $6*1099511627776 + $7*281474976710656 + $8*72057594037927936
        printf "%.0f\n", int(ms / 1000)
    }' 2>/dev/null
}

fix_qcom_time() {
    local rtc_sec=0 awk_bin=""
    if command -v awk >/dev/null 2>&1; then
        awk_bin="awk"
    elif command -v busybox >/dev/null 2>&1; then
        awk_bin="busybox awk"
    else
        return 0
    fi

    if [ -r /sys/class/rtc/rtc0/since_epoch ]; then
        read -r rtc_sec < /sys/class/rtc/rtc0/since_epoch
        rtc_sec=$(echo "$rtc_sec" | tr -dc '0-9')
        rtc_sec="${rtc_sec:-0}"
    fi

    local best_sec=0 best_src="" f ats_sec cand is_better
    for f in /data/vendor/time/ats_2 /data/vendor/time/ats_1 /data/system/time/ats_2 /data/time/ats_2; do
        [ -r "$f" ] || continue
        ats_sec=$(read_ats_sec "$f") || continue
        [ -n "$ats_sec" ] || continue
        cand=$($awk_bin -v r="$rtc_sec" -v a="$ats_sec" 'BEGIN { printf "%.0f\n", r + a }')
        is_better=$($awk_bin -v c="$cand" -v b="$best_sec" 'BEGIN { print (c >= 1735689600 && c <= 2208988800 && c > b) ? 1 : 0 }')
        if [ "$is_better" = "1" ]; then
            best_sec="$cand"
            best_src="$f"
        fi
    done

    if [ "$best_sec" != "0" ]; then
        if busybox date -u -s "@${best_sec}" >/dev/null 2>&1 || date -u "@${best_sec}" >/dev/null 2>&1; then
            echo "I:unified-script: corrected time from ${best_src} -> $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$LOGF"
            return 0
        fi
    fi

    local build_utc now_utc need_clamp
    build_utc=$(getprop ro.build.date.utc 2>/dev/null | tr -dc '0-9')
    now_utc=$(date -u +%s 2>/dev/null | tr -dc '0-9')
    now_utc="${now_utc:-0}"
    if [ -n "$build_utc" ]; then
        need_clamp=$($awk_bin -v b="$build_utc" -v n="$now_utc" 'BEGIN { print (b >= 1735689600 && n < b) ? 1 : 0 }')
        if [ "$need_clamp" = "1" ]; then
            if busybox date -u -s "@${build_utc}" >/dev/null 2>&1 || date -u "@${build_utc}" >/dev/null 2>&1; then
                echo "I:unified-script: clamped stale clock to build date -> $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$LOGF"
            fi
        fi
    fi
}

fix_qcom_time

exit 0

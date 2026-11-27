# OrangeFox Recovery Device Tree for Redmi Note 12 Turbo (`marble`)

This repository contains the OrangeFox Recovery (`fox_16.0`) device tree for Redmi Note 12 Turbo (`marble` / `marblein`). Branch `fox-16` continues linearly from the `17-6.6` device tree and is engineered to support ROMs running either GKI 5.10 or GKI 6.6 kernels.

## Device Specifications

| Component | Specification |
| --- | --- |
| Codename | `marble` (Global/CN), `marblein` (India) |
| SoC | Qualcomm SM7475-AB Snapdragon 7+ Gen 2 (4 nm, `taro` / `ukee`) |
| CPU | Octa-core (1x Cortex-X2, 3x Cortex-A710, 4x Cortex-A510) |
| GPU | Adreno 725 |
| Memory | 8 / 12 / 16 GB LPDDR5 |
| Storage | 256 / 512 GB / 1 TB UFS 3.1 |
| Display | 6.67-inch 1080x2400 AMOLED, 120 Hz, 12-bit backlight |
| Touch Controller | Goodix GT9916S (Berlin SPI, Tianma panels) |
| Battery | 5000 mAh Li-Po, USB-PD / 67W fast charging |
| Connectivity | Wi-Fi 6 (QCA6490), Bluetooth 5.3, NFC (non-IN) |
| Partition Layout | Virtual A/B with dedicated `recovery_a` / `recovery_b`, Boot Header v4 |

## Dual Kernel Support (GKI 5.10 and GKI 6.6)

`marble` uses Boot Header v4 with dedicated `recovery_a` and `recovery_b` partitions. This tree sets `BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true` with a 0-byte kernel placeholder, so the Qualcomm bootloader always pairs the OrangeFox recovery ramdisk with the currently installed ROM's `boot_{a,b}` kernel, `vendor_boot_{a,b}` DTB, and `dtbo_{a,b}`.

Kernel modules are loaded dynamically at recovery boot using `OF_LOAD_ROM_MODULES := 1`, a dangling `lib/modules/modules.load.recovery` symlink staged into the recovery ramdisk via `BOARD_RECOVERY_IMAGE_PREPARE`, and a combined 5.10 and 6.6 `TW_LOAD_VENDOR_MODULES` superset:

- The dangling `lib/modules/modules.load.recovery` ramdisk symlink causes the installed ROM's first-stage init to fall back to normal-boot `modules.load` instead of rebooting on cross-kernel mismatches, while OrangeFox reads the ROM's `modules.load.recovery` directly from `vendor_boot`.
- On GKI 6.6 ROMs, OrangeFox loads matching 6.6 modules from `/vendor_dlkm`, `/system_dlkm`, and `/lib/modules` (including `goodix_ts.ko`, `leds-qti-flash.ko`, `qcom-hv-haptics.ko`, `qti_battery_charger.ko`, `qseecom_dlkm.ko`, `smcinvoke_dlkm.ko`, `pm8941-pwrkey.ko`, `cnss2.ko`, and `qca_cld3_qca6490.ko`).
- On GKI 5.10 ROMs (MIUI 14, HyperOS, or 5.10 AOSP), OrangeFox resolves matching 5.10 modules from `/vendor_dlkm` and `vendor_boot` (including `goodix_core.ko`, `xiaomi_touch.ko`, `adsp_loader_dlkm.ko`, and `qca_cld3_qca6490.ko`) without shipping hardcoded 5.10 `.ko` binaries that would cause vermagic mismatches on 6.6 kernels.
- `recovery.fstab` supports both `ext4` and `erofs` logical partitions and marks `system_dlkm` (6.6 ROMs) and `mi_ext` (5.10 MIUI/HyperOS ROMs) as `nofail` (omitted from `twrp.flags`) so `Prepare_Super_Volume` maps only the partitions present in `super` cleanly.

## Supported Recovery Subsystems

- **FBE Decryption (Android 13-17)**: QSEECom (`qseecomd`), Gatekeeper 1.0, Keymaster 4.1, AOSP 16 patched KeyMint AIDL (`keymint-V4-ndk` + `rkp-V3-ndk`), `keystore2`, and inlinecrypt `wrappedkey_v0` F2FS userdata support.
- **Touchscreen**: Tianma Goodix GT9916S firmware/config images bundled in `/vendor/firmware`, `beforemodules.sh` unprobed-module cleanup, and `postrecoveryboot.sh` recovery for both `goodix_ts` (6.6) and `goodix_core` (5.10), including suspended-IRQ recovery after recovery restarts.
- **WLAN and SoftAP (QCA6490)**: On-demand bring-up via `init.recovery.wifi.rc` triggered by `sys.fox.wlan.up=1`, exposing `/vendor/firmware_mnt -> /firmware` and `/etc/firmware/qca6490 -> /firmware/image` for GKI 6.6 `cnss2` firmware lookups, staging per-device `wlan_mac.bin` from `/persist/qca6490`, and shipping `marble`'s `WCNSS_qcom_cfg.ini`.
- **Flashlight**: PM8350C dual-channel torch configured via `/sys/class/leds/led:torch_0` and `/sys/class/leds/led:switch_0`, with modular `leds-qti-flash.ko` loading on 6.6 kernels.
- **Power, Battery, and Display**: Early `/vendor/firmware_mnt -> /firmware` symlink in `init.recovery.qcom.rc` (`on fs`) and ADSP firmware boot from `modem` for PMIC/charging/remoteproc bring-up, sysfs battery monitoring (`TW_USE_LEGACY_BATTERY_SERVICES := true`), `/sys/class/backlight/panel0-backlight/brightness` control (0-4095, 120 Hz, `TW_NO_SCREEN_BLANK := true`), and `ro.charger.enable_suspend=1`.
- **Haptics**: Open-source QTI AIDL vibrator HAL (`IVibrator/default`) with `marble` PM8350B waveform bins (`effect_0.bin` through `effect_5.bin`).
- **USB and Flashing**: ConfigFS USB gadget (ADB, sideload, MTP, MTP+ADB, fastbootd), USB-OTG storage, Virtual A/B boot control (`android.hardware.boot@1.2-impl-qti`), and hardcoded `Redmi Note 12 Turbo` device/MTP identity.

## Local Build Instructions

1. Sync the official OrangeFox `fox_16.0` manifest:

```bash
mkdir -p ~/OrangeFox_16.0 && cd ~/OrangeFox_16.0
repo init --depth=1 -u https://gitlab.com/OrangeFox/Manifest.git -b fox_16.0
repo sync -c -j$(nproc) --no-clone-bundle --no-tags
```

2. Clone this device tree into `device/xiaomi/marble`:

```bash
git clone https://github.com/nekoshirro/android_device_xiaomi_marble-orangefox.git -b fox-16 device/xiaomi/marble
```

3. Build `recoveryimage`:

```bash
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=marble
export OF_MAINTAINER="YourName"
export FOX_BUILD_TYPE="Unofficial"
source build/envsetup.sh
lunch twrp_marble-bp2a-eng
mka adbd recoveryimage
```

## GitHub Actions CI and Telegram Deployment

The workflow at `.github/workflows/build-orangefox.yml` supports manual `workflow_dispatch` runs against the official public `OrangeFox/Manifest` (`fox_16.0` by default, which includes `OF_LOAD_ROM_MODULES` for dual 5.10/6.6 support). WLAN flags (`OF_ENABLE_WLAN` and `OF_WLAN_AP`) are wired in the device tree and workflow so WLAN activates automatically once upstream OrangeFox merges WLAN sources into public `fox_16.0` (while remaining cleanly ignored on current public `fox_16.0`).

Configure the following Repository Secrets under **Settings -> Secrets and variables -> Actions**:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `TELEGRAM_BOT_TOKEN` | Secret | Required for Telegram | Bot API token generated by `@BotFather`. |
| `TELEGRAM_CHAT_ID` | Secret | Required for Telegram | Numeric private chat ID receiving build artifacts and status messages. |
| `TELEGRAM_TOPIC_ID` | Secret | Optional | Forum topic ID (`message_thread_id`) if sending to a supergroup topic. Leave unset for private chat. |
| `OF_MAINTAINER` | Secret or Variable | Optional | Maintainer name embedded in the OrangeFox build (supports spaces, e.g. `Hafidz Muzakky`; defaults to repository owner). |

The workflow sends build start (`WIB`), completion, and failure notifications to Telegram. Artifacts up to 50 MiB are uploaded directly to Telegram via `sendDocument` with MD5 checksums, while all outputs (including files exceeding the 50 MiB Bot API limit) are published to the GitHub Release and Actions artifacts.

## Flashing Instructions

Boot the device into fastboot mode and flash the recovery image to both slots:

```bash
fastboot flash recovery_ab OrangeFox-*.img
fastboot reboot recovery
```

Alternatively, if OrangeFox is already installed, flash the generated `OrangeFox-*.zip` directly from inside recovery.

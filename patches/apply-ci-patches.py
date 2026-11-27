#!/usr/bin/env python3
"""Apply build-time CI patches to the synced OrangeFox source tree."""

import pathlib
import sys


def replace_unique(
    path: pathlib.Path,
    anchor: str,
    replacement: str,
    marker: str,
    *,
    expected_count: int = 1,
    optional: bool = False,
) -> None:
    if not path.is_file():
        if optional:
            print(f"WARN: {path} not found; skipping optional patch")
            return
        print(f"ERROR: {path} not found", file=sys.stderr)
        sys.exit(1)

    src = path.read_text(encoding="utf-8")
    if marker in src:
        print(f"Already patched: {path} ({marker[:48]}...)")
        return

    count = src.count(anchor)
    if count != expected_count:
        if optional:
            print(f"WARN: expected {expected_count} anchor(s) in {path}, found {count}; skipping")
            return
        print(
            f"ERROR: expected {expected_count} anchor(s) in {path}, found {count}:\n{anchor}",
            file=sys.stderr,
        )
        sys.exit(1)

    path.write_text(src.replace(anchor, replacement), encoding="utf-8")
    print(f"Patched {path} ({count} replacement(s))")


def patch_soong(build_dir: pathlib.Path) -> None:
    anchor = "\tinvocationEnv := make(map[string]string)\n"
    patch = (
        anchor
        + '\tfor _, k := range []string{"GOMEMLIMIT", "GOGC", "GOMAXPROCS"} {\n'
        + '\t\tif v := os.Getenv(k); v != "" {\n'
        + "\t\t\tinvocationEnv[k] = v\n"
        + "\t\t}\n"
        + "\t}\n"
    )
    replace_unique(
        build_dir / "build/soong/ui/build/soong.go",
        anchor,
        patch,
        "GOMEMLIMIT",
        optional=True,
    )


def patch_recovery(build_dir: pathlib.Path) -> None:
    rec = build_dir / "bootable/recovery"

    # 1. Custom console banner in TWFunc::Welcome_Message()
    replace_unique(
        rec / "twrp-functions.cpp",
        '    gui_print("--------------------------\\n");\n    Fox_Has_Welcomed++;\n',
        '    gui_print("\\n");\n'
        '    gui_print_color("green", "Powered by Hafidz Muzakky!\\n");\n'
        '    gui_print("--------------------------\\n");\n'
        '    Fox_Has_Welcomed++;\n',
        'Powered by Hafidz Muzakky!',
    )

    # 2. Sync Skip snapshot creation props at startup
    replace_unique(
        rec / "twrp-functions.cpp",
        '  TWFunc::Welcome_Message();\n',
        '  TWFunc::Welcome_Message();\n'
        '  TWFunc::Fox_Property_Set("ro.virtual_ab.skip_snapshot_check",\n'
        '    DataManager::GetIntValue("tw_vab_skip_snapshot") ? "true" : "false");\n'
        '  TWFunc::Fox_Property_Set("ro.virtual_ab.skip_snapshot_creation",\n'
        '    DataManager::GetIntValue("tw_vab_skip_snapshot") ? "true" : "false");\n',
        'ro.virtual_ab.skip_snapshot_creation',
    )

    # 3. Default tw_vab_skip_snapshot setting to 0
    replace_unique(
        rec / "data.cpp",
        '  mPersist.SetValue(TW_AUTO_REFLASHTWRP_VAR, "1");\n',
        '  mPersist.SetValue(TW_AUTO_REFLASHTWRP_VAR, "1");\n'
        '  mPersist.SetValue("tw_vab_skip_snapshot", "0");\n',
        '"tw_vab_skip_snapshot"',
    )

    # 4. Skip Check_Pending_Merges when /metadata/ota/state does not exist
    replace_unique(
        rec / "partitionmanager.cpp",
        'bool TWPartitionManager::Check_Pending_Merges() {\n',
        'bool TWPartitionManager::Check_Pending_Merges() {\n'
        '\tif (!TWFunc::Path_Exists("/metadata/ota/state"))\n'
        '\t\treturn true;\n',
        '/metadata/ota/state',
    )

    # 5. Propagate Skip snapshot creation props right before A/B payload flash
    replace_unique(
        rec / "twrpinstall/twinstall.cpp",
        '\t\t\tTWFunc::IsRecoveryOverwritten(true);\n',
        '\t\t\tbool skip_snapshot = (DataManager::GetIntValue("tw_vab_skip_snapshot") == 1);\n'
        '\t\t\tTWFunc::Fox_Property_Set("ro.virtual_ab.skip_snapshot_check", skip_snapshot ? "true" : "false");\n'
        '\t\t\tTWFunc::Fox_Property_Set("ro.virtual_ab.skip_snapshot_creation", skip_snapshot ? "true" : "false");\n'
        '\t\t\tTWFunc::IsRecoveryOverwritten(true);\n',
        'bool skip_snapshot =',
    )

    # 6. Add UI string and checkboxes on Install ZIP, Install Queue, and ADB Sideload pages
    replace_unique(
        rec / "gui/theme/common/languages/en.xml",
        '\t</resources>\n</language>\n',
        '\t\t<string name="vab_skip_snapshot">Skip snapshot creation</string>\n'
        '\t</resources>\n</language>\n',
        'name="vab_skip_snapshot"',
    )

    checkbox_anchor = (
        '\t\t\t\t<listitem name="{@inject_twrp_chk}">\n'
        '\t\t\t\t\t<condition var1="tw_has_injecttwrp" var2="1"/>\n'
        '\t\t\t\t\t<data variable="tw_inject_after_zip"/>\n'
        '\t\t\t\t</listitem>\n'
    )
    checkbox_addition = (
        checkbox_anchor
        + '\t\t\t\t<listitem name="{@vab_skip_snapshot=Skip snapshot creation}">\n'
        + '\t\t\t\t\t<condition var1="fox_vab_device" var2="1"/>\n'
        + '\t\t\t\t\t<data variable="tw_vab_skip_snapshot"/>\n'
        + '\t\t\t\t</listitem>\n'
    )
    replace_unique(
        rec / "gui/theme/portrait_hdpi/pages/install.xml",
        checkbox_anchor,
        checkbox_addition,
        "tw_vab_skip_snapshot",
        expected_count=2,
    )
    replace_unique(
        rec / "gui/theme/portrait_hdpi/pages/advanced.xml",
        checkbox_anchor,
        checkbox_addition,
        "tw_vab_skip_snapshot",
    )

    # 7. Install custom maintainer avatar in Settings -> About
    avatar_src = pathlib.Path(__file__).resolve().parent / "maintainer.png"
    avatar_dst = rec / "gui/theme/portrait_hdpi/images/Default/About/maintainer.png"
    if not avatar_src.is_file():
        print(f"ERROR: {avatar_src} not found", file=sys.stderr)
        sys.exit(1)
    if not avatar_dst.parent.is_dir():
        print(f"ERROR: {avatar_dst.parent} not found", file=sys.stderr)
        sys.exit(1)
    avatar_bytes = avatar_src.read_bytes()
    if avatar_dst.is_file() and avatar_dst.read_bytes() == avatar_bytes:
        print(f"Already installed: {avatar_dst}")
    else:
        avatar_dst.write_bytes(avatar_bytes)
        print(f"Installed maintainer avatar: {avatar_dst}")


def patch_update_engine(build_dir: pathlib.Path) -> None:
    ue = build_dir / "system/update_engine/aosp"

    # 1. dynamic_partition_control_android.cc: snapshot creation control
    dpc = ue / "dynamic_partition_control_android.cc"
    replace_unique(
        dpc,
        'bool DynamicPartitionControlAndroid::UnmapAllPartitions() {\n'
        '  GetSnapshotManager()->UnmapAllSnapshots();\n',
        'bool DynamicPartitionControlAndroid::UnmapAllPartitions() {\n'
        '  if (ExpectMetadataMounted()) {\n'
        '    GetSnapshotManager()->UnmapAllSnapshots();\n'
        '  }\n',
        'if (ExpectMetadataMounted()) {\n    GetSnapshotManager()->UnmapAllSnapshots();',
    )

    replace_unique(
        dpc,
        'bool DynamicPartitionControlAndroid::PreparePartitionsForUpdate(\n',
        'static bool IsIncrementalUpdate(const DeltaArchiveManifest& manifest) {\n'
        '  const auto& partitions = manifest.partitions();\n'
        '  return std::any_of(partitions.begin(), partitions.end(), [](const auto& p) {\n'
        '    return p.has_old_partition_info();\n'
        '  });\n'
        '}\n\n'
        'bool DynamicPartitionControlAndroid::PreparePartitionsForUpdate(\n',
        'static bool IsIncrementalUpdate(',
    )

    replace_unique(
        dpc,
        '    if (target_supports_snapshot_) {\n'
        '      if (PrepareSnapshotPartitionsForUpdate(\n'
        '              source_slot, target_slot, manifest, required_size)) {\n'
        '        return true;\n'
        '      }\n',
        '    if (target_supports_snapshot_) {\n'
        '      if (!IsRecovery() ||\n'
        '          (IsRecovery() &&\n'
        '           (IsIncrementalUpdate(manifest) ||\n'
        '            android::base::GetProperty("ro.virtual_ab.skip_snapshot_creation", "") != "true"))) {\n'
        '        if (PrepareSnapshotPartitionsForUpdate(\n'
        '                source_slot, target_slot, manifest, required_size)) {\n'
        '          return true;\n'
        '        }\n'
        '      } else {\n'
        '        LOG(INFO) << "Skip snapshot creation..";\n'
        '        metadata_device_ = nullptr;\n'
        '      }\n',
        'ro.virtual_ab.skip_snapshot_creation',
    )

    replace_unique(
        dpc,
        '  return GetSnapshotManager()->MapAllSnapshots(kMapSnapshotTimeout);\n',
        '  return ExpectMetadataMounted() && GetSnapshotManager()->MapAllSnapshots(kMapSnapshotTimeout);\n',
        'ExpectMetadataMounted() && GetSnapshotManager()->MapAllSnapshots',
    )

    replace_unique(
        dpc,
        'bool DynamicPartitionControlAndroid::UpdateUsesSnapshotCompression() {\n'
        '  return GetVirtualAbFeatureFlag().IsEnabled() &&\n'
        '         GetSnapshotManager()->UpdateUsesCompression();\n}\n',
        'bool DynamicPartitionControlAndroid::UpdateUsesSnapshotCompression() {\n'
        '  return GetVirtualAbFeatureFlag().IsEnabled() && ExpectMetadataMounted() &&\n'
        '         GetSnapshotManager()->UpdateUsesCompression();\n}\n',
        'ExpectMetadataMounted() &&\n         GetSnapshotManager()->UpdateUsesCompression()',
    )

    # 2. cleanup_previous_update_action.cc: snapshot check control
    replace_unique(
        ue / "cleanup_previous_update_action.cc",
        '  if (metadata_device_ == nullptr) {\n'
        '    metadata_device_ = snapshot_->EnsureMetadataMounted();\n'
        '  }\n',
        '  if (metadata_device_ == nullptr) {\n'
        '    metadata_device_ = snapshot_->EnsureMetadataMounted();\n'
        '  }\n\n'
        '  if (kIsRecovery &&\n'
        '      android::base::GetProperty("ro.virtual_ab.skip_snapshot_check", "") == "true") {\n'
        '    LOG(INFO) << "Skip snapshot check..";\n'
        '    processor_->ActionComplete(this, ErrorCode::kSuccess);\n'
        '    return;\n'
        '  }\n',
        'ro.virtual_ab.skip_snapshot_check',
    )


def main() -> None:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <BUILD_DIR>", file=sys.stderr)
        sys.exit(2)

    build_dir = pathlib.Path(sys.argv[1]).resolve()
    patch_soong(build_dir)
    patch_recovery(build_dir)
    patch_update_engine(build_dir)


if __name__ == "__main__":
    main()

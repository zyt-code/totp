# app-icon Specification

## Purpose

让应用包携带专属的 macOS 图标，并在图标资源缺失时由构建脚本自动生成。它只约束图标资源与打包步骤，不改变应用的运行逻辑。

## Requirements

### Requirement: Bundled app icon

The packaged app MUST contain `Contents/Resources/AppIcon.icns`, and the bundled `Info.plist` MUST declare `CFBundleIconFile` as `AppIcon`. The `.icns` MUST be built from the ten standard iconset sizes from `16x16` through `512x512@2x`.

#### Scenario: Bundle carries the icon

- **WHEN** the app bundle is assembled
- **THEN** `Contents/Resources/AppIcon.icns` exists and the bundle plist declares `CFBundleIconFile` as `AppIcon`

#### Scenario: All sizes present

- **WHEN** the iconset is generated
- **THEN** it contains the ten standard sizes from `16x16` to `512x512@2x`

### Requirement: On-demand icon generation

When `Resources/AppIcon.icns` is absent, the packaging script MUST generate it with the icon script before signing, copy it into the bundle, and remove the temporary iconset directory. The icon MUST be in place before the codesign step.

#### Scenario: Missing icon is regenerated

- **WHEN** `Resources/AppIcon.icns` is missing and the packaging script runs
- **THEN** the script generates the icon, copies it into the bundle, and signs the bundle afterwards

#### Scenario: Temporary iconset removed

- **WHEN** the icon script finishes
- **THEN** the intermediate `.iconset` directory no longer exists

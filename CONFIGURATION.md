# Configuration Reference

This document provides a complete reference for `narya` configuration.

## Overview

`narya` uses a merged configuration system:

1. **CLI arguments** - Highest priority, always takes precedence
2. **Project config** - `.narya.yaml` in repository root
3. **Product presets** - Built-in defaults for Firefox/Focus (for l10n commands)
4. **Bundled defaults** - Fallback values built into narya

## Configuration File

The `.narya.yaml` file in your repository root configures narya's behavior.

### All Fields

| Field                   | Type   | Required | Default   | Description                                       |
| ----------------------- | ------ | -------- | --------- | ------------------------------------------------- |
| `project`               | string | Yes      | -         | Project identifier (must be `firefox-ios`)        |
| `default_bootstrap`     | string | No       | `firefox` | Default product for `bootstrap` command           |
| `default_build_product` | string | No       | `firefox` | Default product for `build`/`run`/`test` commands |

### Example Configurations

**Minimal (uses all defaults):**

```yaml
project: firefox-ios
```

**Focus development:**

```yaml
project: firefox-ios
default_bootstrap: focus
default_build_product: focus
```

## L10n Product Presets

The `--product` option on l10n export/import commands provides preset configurations for Firefox and Focus. These presets configure multiple settings at once.

**Important:** For `l10n export` and `l10n import`, you must specify either `--product` or `--project-path`.

### Product Defaults Table

| Setting              | Firefox                 | Focus                         |
| -------------------- | ----------------------- | ----------------------------- |
| `xliff_name`         | `firefox-ios.xliff`     | `focus-ios.xliff`             |
| `export_base_path`   | `/tmp/ios-localization` | `/tmp/ios-localization-focus` |
| `development_region` | `en-US`                 | `en`                          |
| `project_name`       | `Client.xcodeproj`      | `Blockzilla.xcodeproj`        |
| `project_path`       | `Client.xcodeproj`      | `Blockzilla.xcodeproj`        |
| `skip_widget_kit`    | `false`                 | `true`                        |

### Resolution Priority

For l10n commands, values are resolved in this order:

1. **CLI argument** - e.g., `--xliff-name custom.xliff`
2. **Product preset** - from `--product` flag
3. **Hardcoded fallback** - Firefox defaults

## Command-Specific Configuration

### bootstrap

Uses `default_bootstrap` to determine which product to bootstrap:

- `firefox` - Bootstrap for Firefox development
- `focus` - Bootstrap for Focus development

### build / run / test

Uses `default_build_product` to determine which product to build:

- `firefox` - Build Firefox
- `focus` - Build Focus
- `klar` - Build Klar

### l10n export

Requires either `--product` or `--project-path`.

| Option               | Description                                           |
| -------------------- | ----------------------------------------------------- |
| `--product`          | Product preset (firefox/focus). Required unless using --project-path |
| `--project-path`     | Path to .xcodeproj. Required unless using --product   |
| `--xliff-name`       | Override: XLIFF filename                              |
| `--export-base-path` | Override: temp export path                            |

### l10n import

Requires either `--product` or `--project-path`.

| Option                 | Description                                           |
| ---------------------- | ----------------------------------------------------- |
| `--product`            | Product preset (firefox/focus). Required unless using --project-path |
| `--project-path`       | Path to .xcodeproj. Required unless using --product   |
| `--xliff-name`         | Override: XLIFF filename                              |
| `--development-region` | Override: xcloc development region                    |
| `--project-name`       | Override: xcloc project name                          |
| `--skip-widget-kit`    | Override: exclude WidgetKit strings                   |

### l10n templates

| Option         | Description                           |
| -------------- | ------------------------------------- |
| `--product`    | Product preset for xliff-name default |
| `--xliff-name` | Override: XLIFF filename (defaults to firefox-ios.xliff) |

## Usage Examples

### Firefox L10n Export

```bash
# Using product preset
narya l10n export --product firefox --l10n-project-path ~/src/firefox-ios-l10n

# Using explicit project path
narya l10n export --project-path ./Client.xcodeproj --l10n-project-path ~/src/firefox-ios-l10n
```

### Focus L10n Import

```bash
# Using product preset
narya l10n import --product focus --l10n-project-path ~/src/focus-ios-l10n

# Override skip-widget-kit from preset
narya l10n import --product focus --no-skip-widget-kit --l10n-project-path ~/src/focus-ios-l10n
```

### Single Locale Operations

```bash
# Export only French
narya l10n export --product firefox --locale fr --l10n-project-path ~/src/firefox-ios-l10n

# Import only German
narya l10n import --product focus --locale de --l10n-project-path ~/src/focus-ios-l10n
```

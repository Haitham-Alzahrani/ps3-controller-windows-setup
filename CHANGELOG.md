# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/). This project uses [SemVer](https://semver.org/).

## [0.1.0] - 2026-11-01 (pre-release)

First public release.

### Added
- **`Setup-PS3-Controller.cmd`** — self-diagnostic, one-click installer for a PS3 (DualShock 3)
  controller on Windows 10/11:
  - USB (XInput via DsHidMini) and wireless via the **8BitDo dongle** or the PC's **built-in Bluetooth**.
  - Automatic route detection; `/check`, `/dongle`, `/bluetooth`, `/pair`, `/test`, `/uninstall`, `/quiet`.
  - Downloads signed drivers from **official** sources (Nefarius, Microsoft, 8BitDo) with hash verification.
  - Never disables Windows driver-signature enforcement; clean full uninstall.
- **Friendly bilingual window** (`Start Here.cmd` + `gui/`) — English / العربية with right-to-left
  support, one button, wrapping the proven installer. *(New — not yet verified on Windows.)*
- Bilingual docs (`README.md`, `README.ar.md`), `SECURITY.md`, `THIRD-PARTY-NOTICES.md`,
  `CONTRIBUTING.md`, MIT `LICENSE`.

### Known limitations
- The window has not yet had its first real run on Windows — hence this is a **pre-release**.
  The text-mode `Setup-PS3-Controller.cmd` is the proven path.
- Unsigned, so Windows SmartScreen / antivirus may warn on first use.

[0.1.0]: https://github.com/Haitham-Alzahrani/usethis555/releases/tag/v0.1.0

# Third-party notices

This tool installs a controller and (optionally) configures wireless support by
**downloading signed packages from their official sources at run time** and, for
one driver, **bundling** it. Each component keeps its own license. This project's
own code is MIT (see `LICENSE`).

> Verification status: component names, versions, sources, and license *families*
> below are taken from the installer's download URLs and each project's README.
> Items marked **(verify)** still need the exact LICENSE text confirmed before a
> public release.

## Downloaded at install time (NOT redistributed by this project)

| Component | Version | Source (official) | License |
|---|---|---|---|
| Nefarius DsHidMini (DualShock 3 HID driver) | 3.27.0 | `github.com/nefarius/DsHidMini/releases` | BSD-3-Clause (+ other components; see its LICENSE files) |
| Nefarius BthPS3 (Bluetooth profile/filter driver) | 3.2.1 | `github.com/nefarius/BthPS3/releases` | Drivers & setup BSD-3-Clause; userland MIT |
| Nefarius ViGEmBus (virtual gamepad bus) | 1.22.0 | `github.com/nefarius/ViGEmBus/releases` | BSD-3-Clause (project retired/feature-frozen) |
| Nefarius.ViGEm.Client (.NET client lib) | 1.21.256 | `api.nuget.org` | MIT **(verify)** |
| .NET Desktop Runtime | 10.0.14 | `builds.dotnet.microsoft.com` | MIT (Microsoft) |
| 8BitDo PS3 pairing tool | Win V1.4 | `download.8bitdo.com` | Proprietary — 8BitDo. Downloaded only; not redistributed **(verify terms)** |

Because these are fetched from each vendor's own release page, this project does
not redistribute them. The installer verifies downloads against pinned hashes.

## Bundled in this repository (redistributed)

| Component | Source | License |
|---|---|---|
| libusb-win32 USB driver for the DS3 (`driver/`, incl. `.inf`/`.cat`, `libusb0`, `libusbK`) | libusb-win32 project | GNU LGPL — license text included at `driver/license/libusb0/installer_license.txt` |

LGPL redistribution requires the license text (included) and that users can obtain
the corresponding source. libusb-win32 source: https://sourceforge.net/projects/libusb-win32/

## Not affiliated

This is a community tool. It is **not affiliated with or endorsed by** Sony
Interactive Entertainment, Nefarius Software Solutions, 8BitDo, or Microsoft.
Product and project names are used only to identify the components involved.
Per the BSD-3-Clause terms of the Nefarius components, their names are not used
to endorse or promote this tool.

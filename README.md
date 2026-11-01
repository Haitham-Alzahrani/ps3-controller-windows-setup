<div align="center">

# 🎮 PS3 Controller Setup for Windows

### Use a PlayStation 3 (DualShock 3) controller on your PC — the easy way

![Windows](https://img.shields.io/badge/Windows-10%20%26%2011-0078D6?logo=windows&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)
![Docs](https://img.shields.io/badge/docs-English%20%7C%20العربية-blue)
![No signing needed](https://img.shields.io/badge/Zadig-not%20needed-success)

**🌐 Language:** **English** · [العربية](README.ar.md)

Make a **PS3 (DualShock 3 / Sixaxis)** controller work on **Windows 10 & 11** — over **USB**
and **wirelessly** — in about a minute, with one click.
No Zadig, no Device Manager, no commands. Made for people who have never touched Windows settings. 

</div>

---

## 📑 Contents
- [What it does](#-what-it-does)
- [Quick start](#-quick-start-3-steps)
- [What you need](#-what-you-need)
- [How it works](#-how-it-works)
- [Remove it](#-remove-it)
- [FAQ](#-faq)
- [Troubleshooting](#-troubleshooting)
- [Is it safe? What it changes](#-is-it-safe-what-it-changes)
- [Credits & license](#-credits)

---

## ✨ What it does

| | |
|---|---|
| 🔌 **USB** | Your controller works through the cable — shows up like an Xbox pad, so games just work. |
| 📡 **Wireless** | Through your **8BitDo adapter** *or* your PC's **built-in Bluetooth** — whichever your PC's radio supports (run `/check`). |
| 🤖 **Automatic** | It detects your PC and picks the right method. You choose nothing. |
| 🧹 **Reversible** | One click puts your PC back exactly how it was. |
| 🔒 **Private** | Collects **no data**. Changes nothing about your games. |

---

## 🚀 Quick start (3 steps)

| 1️⃣ Download | 2️⃣ Open | 3️⃣ Play |
|---|---|---|
| Green **`Code`** button → **Download ZIP**, then unzip it | Plug the controller in with the cable, then **double-click `Start Here.cmd`** and click **Yes** | When it says **All done**, unplug the cable and press the round **PS** button 🎮 |

> 💡 **Prefer no window?** Double-click **`Setup-PS3-Controller.cmd`** instead — same setup, simple text window. This is the **most-tested** path; use it if the window ever gives trouble.
>
> 🌍 In the window you can switch between **English** and **العربية** in the corner.

*(A screenshot of the window will be added here once it's captured on Windows.)*

---

## 🧰 What you need

- A **PS3 (DualShock 3 / Sixaxis)** controller
- A **USB cable** for it (mini-USB)
- **Windows 10 or 11, 64-bit**
- *Optional:* an **8BitDo USB wireless adapter** (for the dongle route)

---

## ⚙️ How it works

<details>
<summary><b>In plain words</b></summary>

Windows doesn't include a driver for the PS3 controller. This tool installs the right one for you,
downloads the wireless pieces from their official makers, sets everything up, and tests it — then
tells you to press PS. If you ever want it gone, it removes all of it.

</details>

<details>
<summary><b>For the technically curious</b></summary>

- The controller is driven as an Xbox-style pad (XInput) via **DsHidMini**.
- Wireless uses either the **8BitDo adapter** (the pad is paired to the dongle) or the PC's own radio via **BthPS3** + Bluetooth.
- The installer **downloads signed drivers from their official release pages** (Nefarius, Microsoft, 8BitDo) and verifies each against a known hash.
- It **never disables Windows driver-signature enforcement.** The only bundled driver is the open-source **libusb-win32** USB driver for the controller.
- Full detail: **[docs/advanced-usage.md](docs/advanced-usage.md)** and **[SECURITY.md](SECURITY.md)**.

</details>

---

## 🧹 Remove it

Open the window and click **Remove**, or run:
```
Setup-PS3-Controller.cmd /uninstall
```
It removes the driver, the certificate, the helper, and everything else it added.

---

## ❓ FAQ

<details><summary><b>Do I need an 8BitDo adapter, or will my PC's Bluetooth work?</b></summary>
It depends on your PC's Bluetooth radio. If it's compatible, you don't need an adapter — the PC's own Bluetooth is used. But some radios <b>cannot</b> be used for wireless — most notably <b>Qualcomm Atheros AR3012</b> (as in the MSI GS60) — and on those PCs an <b>8BitDo adapter</b> or a <b>compatible USB Bluetooth dongle</b> is <b>required</b> (see "Will your PC's Bluetooth work?" below). The USB cable always works. Run <code>Setup-PS3-Controller.cmd /check</code> first — it tells you which route you need.
</details>

<details><summary><b>Will it mess up my other Bluetooth devices?</b></summary>
No — the Bluetooth route is installed in a shared mode so your mouse, headphones, etc. keep working.
</details>

<details><summary><b>Does it work with clone / third-party PS3 controllers?</b></summary>
It targets genuine Sony DualShock 3 hardware. Clones may use different chips and aren't guaranteed.
</details>

<details><summary><b>Is it free? Does it phone home?</b></summary>
Completely free and open-source. It collects and sends no data.
</details>

<details><summary><b>Why does Windows / my antivirus warn me?</b></summary>
Because it's not signed with a paid certificate — normal for free driver tools. It's open-source and
only downloads from official sources. Choose <b>Keep</b> / <b>Allow</b>. See <a href="SECURITY.md">SECURITY.md</a>.
</details>

---

## 📶 Will your PC's Bluetooth work for wireless?

Wireless over your PC's **built-in** Bluetooth depends on the radio. **Run `Setup-PS3-Controller.cmd /check` first** — it reads your radio and tells you which route you need, changing nothing.

Two things can rule out the built-in radio:
- **Unsupported radio** → Windows shows a *Code 10* and there is **no software fix** — you need different Bluetooth hardware. (A radio must be USB-based, or bind to BTHX/BthMini on BthPS3 v3+, and report **LMP ≥ 3** / Bluetooth 2.0+EDR — [Nefarius FAQ](https://docs.nefarius.at/projects/BthPS3/Frequently-Asked-Questions/).)
- **Radio crashes on install** → *"Device Descriptor Request Failed"*, setup fails (code 1603), and it only recovers after a **full power-off**. The **Qualcomm Atheros AR3012** (e.g. **MSI GS60**) does exactly this.

**Known-problem radios — use an adapter/dongle instead:**

| Radio | Status |
|---|---|
| Qualcomm Atheros **AR3012** (`VID_0CF3&PID_3004`) | ❌ Confirmed (MSI GS60) |
| Qualcomm Atheros **AR3011 / AR3012** family | ⚠️ Expected — same generation |
| Qualcomm **QCA61x4 / QCA9377** | ⚠️ Reported with the same error — confirm with `/check` |

No list is exhaustive, so trust **`/check`** over any list.

### If your built-in Bluetooth can't be used — two ways to get wireless

1. **8BitDo Wireless USB Adapter** *(what the GS60 uses — most reliable)*. The controller pairs **to the adapter**, bypassing Bluetooth completely. Buy the **8BitDo Wireless USB Adapter 2** (current model; officially lists DualShock 3 support) — the original **8BitDo Wireless USB Adapter** (retired) also works via the PS3 tool. Avoid "2.4G"-only models and no-name clones.
2. **A compatible USB Bluetooth dongle.** Adds a radio the Bluetooth route can use. Choose a **genuine CSR8510-based Bluetooth 4.0 dongle** from a known brand — many cheap "CSR8510" dongles are counterfeits that won't work. Plug it in, and wireless uses it instead of the built-in radio.

---

## 🩺 Troubleshooting

| Problem | Fix |
|---|---|
| One light stays on, buttons dead | Hold **PS** 10 seconds until the light goes off, then press **PS** again |
| Lights flash then go off | Paired to another PC. Plug in the cable, press **PS** within 30 seconds |
| Won't connect wirelessly | Run `Setup-PS3-Controller.cmd /pair` |
| The window won't open | Use `Setup-PS3-Controller.cmd` directly (the proven path) |
| MSI GS60 laptop | Use the **dongle** route; its built-in Bluetooth needs a full power-off after setup |

See every command in **[docs/advanced-usage.md](docs/advanced-usage.md)**.

---

## 🔒 Is it safe? What it changes

Yes — and it's fully transparent. It installs a controller driver, adds a certificate so that driver
is trusted (removed again on uninstall), installs a small background helper for the wireless link, and
downloads official drivers. **Driver-signature enforcement is never disabled.** Every change and how
it's undone is listed in **[SECURITY.md](SECURITY.md)**. What it installs and each license:
**[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)**.

---

## 🙏 Credits

Built on the excellent open-source work of **[Nefarius](https://github.com/nefarius)**
— [DsHidMini](https://github.com/nefarius/DsHidMini), [BthPS3](https://github.com/nefarius/BthPS3),
[ViGEmBus](https://github.com/nefarius/ViGEmBus) — and the
[**libusb-win32**](https://sourceforge.net/projects/libusb-win32/) project. Thank you.

**Not affiliated** with Sony, Nefarius, 8BitDo, or Microsoft. Names are used only to say what it works with.

## 📜 License

[MIT](LICENSE) for this project's own code. Bundled/downloaded parts keep their own licenses —
see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

# Contributing

Thanks for helping! This project aims to make a PS3 controller work on Windows with **zero
technical knowledge required** — please keep that goal in mind for any change.

## Reporting a problem

Open an [issue](../../issues/new/choose) and include:

1. Your **Windows version** (10 or 11) and whether it's 64-bit.
2. Your **controller** (genuine Sony DualShock 3, or a clone/third-party).
3. Whether you use an **8BitDo dongle**.
4. The output of the read-only check — run this and paste what it prints:
   ```
   Setup-PS3-Controller.cmd /check
   ```
5. What you expected vs. what happened.

Never paste anything secret; `/check` output is safe (it only describes hardware).

## Adding or fixing a translation

Translations live in **`gui/lang/`** as UTF-8 JSON files, one per language (`en.json`, `ar.json`, …).

- Keep every key that exists in `en.json`.
- Save as **UTF-8**.
- To add a new language, copy `en.json` to `xx.json` (the language code), translate the values,
  and open a pull request. The window picks it up automatically.

## Code

- The driver/setup logic lives in **`Setup-PS3-Controller.cmd`** (PowerShell inside a `.cmd`
  wrapper). The friendly window is **`gui/PS3SetupGui.ps1`** and only *calls* the setup script —
  please keep that separation so the proven engine stays intact.
- Prefer small, reversible changes. Anything that touches drivers should be undoable by
  `/uninstall`.
- Test on a real Windows machine before submitting.

## Ground rules

- Only download drivers from their **official** sources.
- **Never** disable Windows driver-signature enforcement.
- Keep it honest with users about what is installed and how to remove it.

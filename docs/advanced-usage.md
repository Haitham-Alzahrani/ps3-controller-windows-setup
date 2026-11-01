# PS3 controller setup

Makes a DualShock 3 work on 64-bit Windows 10/11, over USB and wirelessly.

## Set it up

1. Plug in the 8BitDo dongle, if you use one. Don't press its button.
2. Unplug the controller's cable.
3. Double-click `Setup-PS3-Controller.cmd` and click Yes on the admin prompt.

It picks the route for your PC. Run it again any time; it's safe to repeat.

| Route | When | How it works |
|---|---|---|
| **Dongle** | 8BitDo dongle plugged in, or a radio that can't run BthPS3 | Wireless through the dongle. With the dongle out, the cable is the gamepad |
| **Bluetooth** | No dongle, and a compatible radio | Wireless through the PC's own Bluetooth (DsHidMini and BthPS3) |

**First time with a new dongle or controller:** run it once with `/pair`, from a terminal, and follow the steps it shows.

## Use it: dongle route

Don't press the dongle's button.

| You want to | Do this |
|---|---|
| Play wirelessly | Press PS |
| Plug or unplug the cable while playing | Nothing. It stays connected and the cable charges it |
| Start playing, cable in, controller off | Plug in, then press PS within 30 seconds |
| Charge with the controller off | Plug in. After 30 seconds, four lights flash |
| Play when four lights are flashing | Unplug the cable, then press PS |
| Come back from another PC | Plug in the cable, then press PS within 30 seconds |
| Play without the dongle | Plug in the cable and wait 6 seconds. No PS needed |

## Use it: Bluetooth route

Plug in the cable once, wait 5 seconds, unplug it, and press PS.

## Commands

| Command | What it does |
|---|---|
| `Setup-PS3-Controller.cmd` | Sets up the best route, then tests |
| `/check` | Reports on this PC and changes nothing |
| `/test` | Waits for you to press X, and shows the route it came through |
| `/dongle` or `/bluetooth` | Sets up that route |
| `/pair` | Pairs the controller with a dongle |
| `/uninstall` | Removes the dongle route |
| `/quiet` | Add after a command to skip the test and the pause |

## Troubleshooting

| Problem | Fix |
|---|---|
| One steady light, buttons dead | Hold PS for 10 seconds until the light goes off, then press PS |
| Lights flash, then go off | It's paired elsewhere. Plug in the cable, then press PS within 30 seconds |
| Still won't link | Run `/pair` |
| Bluetooth disappeared | Turn the PC fully off: hold Shift while clicking Shut down |
| ScpToolkit blocks setup | Uninstall it in Windows Settings > Apps, then run setup again |
| Helper blocked by antivirus | Allow `installed\PS3LinkHelper.exe` |

## Good to know

- **Dongle route, cable only charges while the dongle is in.** The USB-gamepad driver is what caused the stuck connection, so it's removed. If you had DsHidMini or BthPS3 on that PC, setup uninstalls them.
- **Don't install BthPS3 on an MSI GS60.** Its setup knocks out the AR3012 radio until a full power-off.
- **What dongle setup adds:**
  - a small USB driver, with its own certificate in Windows' trusted list
  - `installed\PS3LinkHelper.exe`, which starts when you sign in
  - ViGEmBus, a retired driver that won't get fixes
  - on radios known to fail on wake, a task that resets the radio only if Windows reports it failed

## What's in this folder

| Path | What it is |
|---|---|
| `Setup-PS3-Controller.cmd` | The installer |
| `helper\PS3LinkHelper.cs` | Helper source, built during setup |
| `driver\` | The small USB driver |
| `installed\`, `installers\` | Created by setup, not stored in git |

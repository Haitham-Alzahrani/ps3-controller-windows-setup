// PS3 Link Helper. Runs in the background on the GS60 and looks after a DualShock 3 on its cable.
// The controller is bound to the plain libusb-win32 driver, so by default USB charges it but never
// streams, and it stays wireless through the 8BitDo dongle.
//  - Whenever the controller is on the cable, its stored host address is set to the dongle's.
//    This undoes what another PC (the Victus) writes when the cable is plugged in there.
//  - A controller that is off on a configured USB port flashes all four lights and ignores PS,
//    with no way to detect the press. So after plugging in with the controller off, USB stays
//    released for a while so PS can link it, and only then goes back to charging.
//  - If the dongle is unplugged, the cable becomes the gamepad: this starts USB streaming and feeds
//    a virtual Xbox controller through ViGEmBus. Plugging the dongle back in stops it.
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;

static class Lu {
    const string D = "libusb0.dll";
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern void usb_init();
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_find_busses();
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_find_devices();
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern IntPtr usb_get_busses();
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern IntPtr usb_open(IntPtr dev);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_close(IntPtr h);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_set_configuration(IntPtr h, int c);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_claim_interface(IntPtr h, int iface);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_release_interface(IntPtr h, int iface);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_control_msg(IntPtr h, int type, int req, int val, int idx, byte[] data, int size, int timeout);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_interrupt_read(IntPtr h, int ep, byte[] data, int size, int timeout);
    [DllImport(D, CallingConvention = CallingConvention.Cdecl)] public static extern int usb_interrupt_write(IntPtr h, int ep, byte[] data, int size, int timeout);

    // 64-bit layout from libusb-win32's lusb0_usb.h: path buffers are 512 bytes.
    public static IntPtr FindPad() {
        usb_find_busses();
        usb_find_devices();
        for (IntPtr bus = usb_get_busses(); bus != IntPtr.Zero; bus = Marshal.ReadIntPtr(bus, 0)) {
            for (IntPtr dev = Marshal.ReadIntPtr(bus, 16 + 512); dev != IntPtr.Zero; dev = Marshal.ReadIntPtr(dev, 0)) {
                if ((ushort)Marshal.ReadInt16(dev, 536 + 8) == 0x054C && (ushort)Marshal.ReadInt16(dev, 536 + 10) == 0x0268) return dev;
            }
        }
        return IntPtr.Zero;
    }
}

static class XI {
    [StructLayout(LayoutKind.Sequential)]
    struct State { public uint Packet; public ushort Buttons; public byte LT; public byte RT; public short LX; public short LY; public short RX; public short RY; }
    [DllImport("xinput1_4.dll")] static extern int XInputGetState(int user, out State state);
    // With the dongle in, it only shows up as a gamepad while a controller is linked to it.
    public static bool Linked() { for (int i = 0; i < 4; i++) { State s; if (XInputGetState(i, out s) == 0) return true; } return false; }
}

static class Devices {
    const uint FilterEnumerator = 0x1, FilterPresent = 0x100;
    [DllImport("cfgmgr32.dll", CharSet = CharSet.Unicode)] static extern int CM_Get_Device_ID_List_SizeW(out uint len, string filter, uint flags);
    [DllImport("cfgmgr32.dll", CharSet = CharSet.Unicode)] static extern int CM_Get_Device_ID_ListW(string filter, char[] buf, uint len, uint flags);

    // Assumes the dongle is present if Windows can't answer, so the cable stays out of the way.
    public static bool DonglePresent() {
        uint flags = FilterEnumerator | FilterPresent, len;
        if (CM_Get_Device_ID_List_SizeW(out len, "USB", flags) != 0) return true;
        char[] buf = new char[len];
        if (CM_Get_Device_ID_ListW("USB", buf, len, flags) != 0) return true;
        return new string(buf).IndexOf("VID_2DC8", StringComparison.OrdinalIgnoreCase) >= 0;
    }
}

static class Program {
    const int GetReport = 0x01, SetReport = 0x09, ClassIn = 0xA1, ClassOut = 0x21;
    const int FeatureHost = 0x03F5, FeatureControl = 0x03F4, OutputMain = 0x0201, InputPipe = 0x81, OutputPipe = 0x02;
    const int WakeWindowSeconds = 30;
    static readonly string Dir = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
    static readonly string LogPath = Path.Combine(Dir, "PS3LinkHelper.log");
    static byte[] Target;
    static ViGEmClient Bus;
    static bool BusFailed;
    static volatile int RumbleLarge, RumbleSmall;

    static void Log(string text) {
        try {
            if (File.Exists(LogPath) && new FileInfo(LogPath).Length > 256 * 1024) File.Delete(LogPath);
            File.AppendAllText(LogPath, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "  " + text + Environment.NewLine);
        } catch { }
    }

    static string Hex(byte[] b, int from, int n) { return BitConverter.ToString(b, from, n).Replace("-", ""); }

    static byte[] ReadTarget() {
        string s = File.ReadAllText(Path.Combine(Dir, "dongle-address.txt")).Trim();
        if (s.Length != 12) throw new FormatException("dongle-address.txt must hold 12 hex characters");
        byte[] a = new byte[6];
        for (int i = 0; i < 6; i++) a[i] = Convert.ToByte(s.Substring(i * 2, 2), 16);
        return a;
    }

    // Returns false if the controller has gone away. An unconfigured controller answers with 0 bytes.
    static bool CheckAddress(IntPtr h) {
        byte[] f5 = new byte[8];
        int r = Lu.usb_control_msg(h, ClassIn, GetReport, FeatureHost, 0, f5, 8, 1000);
        if (r < 0) return false;
        if (r < 8) {
            Lu.usb_set_configuration(h, 1);
            Thread.Sleep(300);
            r = Lu.usb_control_msg(h, ClassIn, GetReport, FeatureHost, 0, f5, 8, 1000);
            if (r < 8) return r >= 0;
        }
        bool same = true;
        for (int i = 0; i < 6; i++) if (f5[2 + i] != Target[i]) same = false;
        if (same) return true;
        Log("stored address is " + Hex(f5, 2, 6) + ", writing " + Hex(Target, 0, 6));
        byte[] w = new byte[8];
        w[0] = 1;
        Array.Copy(Target, 0, w, 2, 6);
        r = Lu.usb_control_msg(h, ClassOut, SetReport, FeatureHost, 0, w, 8, 1000);
        Thread.Sleep(100);
        byte[] v = new byte[8];
        int rv = Lu.usb_control_msg(h, ClassIn, GetReport, FeatureHost, 0, v, 8, 1000);
        Log("write result=" + r + ", now " + (rv >= 8 ? Hex(v, 2, 6) : "unreadable"));
        return r >= 0;
    }

    // The dongle vanishes for about a second each time it switches between idle and Xbox mode,
    // so it only counts as unplugged once it has been gone for 3 seconds.
    static bool DongleStaysOut() {
        for (int i = 0; i < 15; i++) {
            if (Devices.DonglePresent()) return false;
            Thread.Sleep(200);
        }
        return true;
    }

    // Returns false if the controller went away during the window.
    static bool WakeWindow(IntPtr h) {
        Log("not linked: USB released for " + WakeWindowSeconds + " seconds so PS can link it");
        Lu.usb_set_configuration(h, 0);
        DateTime end = DateTime.Now.AddSeconds(WakeWindowSeconds);
        byte[] probe = new byte[8];
        while (DateTime.Now < end && !XI.Linked()) {
            if (Lu.usb_control_msg(h, ClassIn, GetReport, FeatureHost, 0, probe, 8, 1000) < 0) return false;
            if (DongleStaysOut()) break;
            Thread.Sleep(200);
        }
        Log(XI.Linked() ? "linked to the dongle" : "no PS press: back to charging");
        Lu.usb_set_configuration(h, 1);
        return true;
    }

    // Same layout as DsHidMini's USB report: report ID, rumble, light flags at byte 10 (0x02 is
    // player light 1), then one steady-light effect per light. Sent on the interrupt pipe.
    static void SendOutput(IntPtr h, int large, int small) {
        byte[] o = new byte[49];
        o[0] = 0x01;
        o[2] = 0xFF;
        o[3] = (byte)(small > 0 ? 1 : 0);
        o[4] = 0xFF;
        o[5] = (byte)large;
        o[10] = 0x02;
        for (int i = 0; i < 4; i++) {
            int at = 11 + i * 5;
            o[at] = 0xFF; o[at + 1] = 0x00; o[at + 2] = 0x01; o[at + 3] = 0x00; o[at + 4] = 0x01;
        }
        Lu.usb_interrupt_write(h, OutputPipe, o, 49, 200);
    }

    static void SetStreaming(IntPtr h, bool on) {
        byte[] c = new byte[] { 0x42, (byte)(on ? 0x0C : 0x0B), 0x00, 0x00 };
        int r = Lu.usb_control_msg(h, ClassOut, SetReport, FeatureControl, 0, c, 4, 1000);
        Log("USB streaming " + (on ? "on" : "off") + ", result=" + r);
    }

    static short StickX(byte v) { int a = (v - 128) * 257; return (short)Math.Max(-32768, Math.Min(32767, a)); }
    static short StickY(byte v) { int a = (127 - v) * 257; return (short)Math.Max(-32768, Math.Min(32767, a)); }

    static ushort MapButtons(byte[] d) {
        int b = 0;
        if ((d[2] & 0x01) != 0) b |= 0x0020; // Select -> Back
        if ((d[2] & 0x02) != 0) b |= 0x0040; // L3
        if ((d[2] & 0x04) != 0) b |= 0x0080; // R3
        if ((d[2] & 0x08) != 0) b |= 0x0010; // Start
        if ((d[2] & 0x10) != 0) b |= 0x0001; // Up
        if ((d[2] & 0x20) != 0) b |= 0x0008; // Right
        if ((d[2] & 0x40) != 0) b |= 0x0002; // Down
        if ((d[2] & 0x80) != 0) b |= 0x0004; // Left
        if ((d[3] & 0x04) != 0) b |= 0x0100; // L1 -> LB
        if ((d[3] & 0x08) != 0) b |= 0x0200; // R1 -> RB
        if ((d[3] & 0x10) != 0) b |= 0x8000; // Triangle -> Y
        if ((d[3] & 0x20) != 0) b |= 0x2000; // Circle -> B
        if ((d[3] & 0x40) != 0) b |= 0x1000; // Cross -> A
        if ((d[3] & 0x80) != 0) b |= 0x4000; // Square -> X
        if ((d[4] & 0x01) != 0) b |= 0x0400; // PS -> Guide
        return (ushort)b;
    }

    // Cable as gamepad, for when the dongle is out. Returns false if the controller went away.
    static bool UsbMode(IntPtr h) {
        if (BusFailed) return true;
        IXbox360Controller pad;
        try {
            if (Bus == null) Bus = new ViGEmClient();
            pad = Bus.CreateXbox360Controller();
            pad.AutoSubmitReport = false;
            pad.FeedbackReceived += (s, e) => { RumbleLarge = e.LargeMotor; RumbleSmall = e.SmallMotor; };
            pad.Connect();
        } catch (Exception e) {
            BusFailed = true;
            Log("virtual gamepad unavailable: " + e.Message);
            return true;
        }
        Log("dongle is out: cable is now the gamepad");
        Lu.usb_set_configuration(h, 1);
        Lu.usb_claim_interface(h, 0);
        Thread.Sleep(100);
        byte[] zero = new byte[48];
        Lu.usb_control_msg(h, ClassOut, SetReport, OutputMain, 0, zero, 48, 500);
        SetStreaming(h, true);
        SendOutput(h, 0, 0);
        RumbleLarge = 0;
        RumbleSmall = 0;

        bool here = true;
        int large = 0, small = 0;
        byte[] d = new byte[49];
        byte[] probe = new byte[8];
        DateTime nextCheck = DateTime.Now.AddSeconds(1);
        while (true) {
            int r = Lu.usb_interrupt_read(h, InputPipe, d, 49, 100);
            if (r >= 20) {
                pad.SetButtonsFull(MapButtons(d));
                pad.SetAxisValue(Xbox360Axis.LeftThumbX, StickX(d[6]));
                pad.SetAxisValue(Xbox360Axis.LeftThumbY, StickY(d[7]));
                pad.SetAxisValue(Xbox360Axis.RightThumbX, StickX(d[8]));
                pad.SetAxisValue(Xbox360Axis.RightThumbY, StickY(d[9]));
                pad.SetSliderValue(Xbox360Slider.LeftTrigger, d[18]);
                pad.SetSliderValue(Xbox360Slider.RightTrigger, d[19]);
                pad.SubmitReport();
            }
            int l = RumbleLarge, m = RumbleSmall;
            if (l != large || m != small) { large = l; small = m; SendOutput(h, l, m); }
            if (DateTime.Now >= nextCheck) {
                nextCheck = DateTime.Now.AddSeconds(1);
                SendOutput(h, large, small); // The PS3 keeps resending this too; a single send can be missed.
                if (Lu.usb_control_msg(h, ClassIn, GetReport, FeatureHost, 0, probe, 8, 500) < 0) { here = false; break; }
                if (Devices.DonglePresent()) break;
            }
        }
        try { pad.Disconnect(); } catch { }
        if (here) {
            SendOutput(h, 0, 0);
            SetStreaming(h, false);
            Lu.usb_release_interface(h, 0);
            Log("dongle is back: cable is no longer the gamepad");
        }
        return here;
    }

    static void Main() {
        bool first;
        using (new Mutex(true, @"Local\PS3LinkHelper", out first)) {
            if (!first) return;
            try { Target = ReadTarget(); } catch (Exception e) { Log("cannot start: " + e.Message); return; }
            Lu.usb_init();
            Log("started, dongle address " + Hex(Target, 0, 6));
            IntPtr h = IntPtr.Zero;
            while (true) {
                try {
                    if (h == IntPtr.Zero) {
                        IntPtr dev = Lu.FindPad();
                        if (dev == IntPtr.Zero) { Thread.Sleep(1000); continue; }
                        h = Lu.usb_open(dev);
                        if (h == IntPtr.Zero) { Thread.Sleep(1000); continue; }
                        Log("controller on the cable");
                        Thread.Sleep(300);
                        bool here = CheckAddress(h);
                        if (here && Devices.DonglePresent() && !XI.Linked()) here = WakeWindow(h);
                        if (!here) { Lu.usb_close(h); h = IntPtr.Zero; Log("controller off the cable"); }
                        continue;
                    }
                    bool alive = CheckAddress(h);
                    if (alive && !BusFailed && DongleStaysOut()) {
                        alive = UsbMode(h);
                        if (alive && Devices.DonglePresent()) alive = WakeWindow(h);
                    }
                    if (!alive) {
                        Lu.usb_close(h);
                        h = IntPtr.Zero;
                        Log("controller off the cable");
                        continue;
                    }
                    Thread.Sleep(1000);
                } catch (Exception e) {
                    Log("error: " + e.Message);
                    Thread.Sleep(2000);
                }
            }
        }
    }
}

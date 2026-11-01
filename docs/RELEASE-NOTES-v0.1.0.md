# v0.1.0 — First public release (pre-release)

🎮 **Make a PlayStation 3 (DualShock 3 / Sixaxis) controller work on Windows 10 & 11 — over USB and wirelessly — with one click.**

No Zadig, no Device Manager, no commands. Built for people who have never touched Windows settings.

## ✨ Highlights
- **USB + wireless** — works through the cable (as an Xbox-style pad) and wirelessly via your **8BitDo dongle** *or* your PC's **built-in Bluetooth**.
- **Automatic** — it detects your PC and picks the right method; you choose nothing.
- **Safe & reversible** — never disables Windows driver-signature enforcement; one-click **uninstall** restores your PC.
- **Downloads only from official sources** (Nefarius, Microsoft, 8BitDo), each verified by hash.
- **Bilingual** — English and العربية, with a friendly window (right-to-left supported).
- **Open-source**, collects **no data**.

## 📥 How to use
1. Download **Source code (zip)** below and unzip it.
2. Plug the controller in with the cable, then double-click **`Start Here.cmd`** and click **Yes**.
3. When it says **All done**, unplug the cable and press the round **PS** button.

Prefer no window? Double-click **`Setup-PS3-Controller.cmd`** — same setup, simple text window (the most-tested path).

## ⚠️ Known limitations (why this is a pre-release)
- The friendly **window hasn't been verified on Windows yet** — the proven `Setup-PS3-Controller.cmd` is the reliable path for now.
- Because it isn't signed with a paid certificate, **Windows SmartScreen or antivirus may warn** on first use — choose *Keep* / *Allow*. It's open-source; see [SECURITY.md](../SECURITY.md).
- Targets **genuine** Sony DualShock 3 hardware; clones may differ.

## 🙏 Credits
Built on [Nefarius](https://github.com/nefarius)' DsHidMini, BthPS3, and ViGEmBus, and the libusb-win32 project. Not affiliated with Sony, Nefarius, 8BitDo, or Microsoft.

---

<div dir="rtl">

# الإصدار v0.1.0 — أول إصدار عام (إصدار تجريبي)

🎮 **اجعل يد تحكم بلايستيشن 3 (DualShock 3 / Sixaxis) تعمل على ويندوز 10 و 11 — عبر USB ولاسلكيًا — بنقرة واحدة.**

بلا Zadig، وبلا Device Manager، وبلا أوامر. صُمِّم لمن لم يسبق له تعديل إعدادات ويندوز.

## ✨ أبرز المزايا
- **USB ولاسلكي** — تعمل عبر الكابل (كيد بنمط Xbox) ولاسلكيًا عبر **محوّل 8BitDo** أو **بلوتوث الكمبيوتر المدمج**.
- **تلقائي** — يكتشف جهازك ويختار الطريقة المناسبة؛ لا تختار أنت شيئًا.
- **آمن وقابل للتراجع** — لا يُعطّل إطلاقًا فرض توقيع التعريفات؛ وإلغاء التثبيت بنقرة واحدة يُعيد جهازك إلى حالته.
- **ينزّل من المصادر الرسمية فقط** (Nefarius وMicrosoft و8BitDo)، مع التحقق من كل ملف ببصمة.
- **ثنائي اللغة** — الإنجليزية والعربية، مع نافذة سهلة تدعم الاتجاه من اليمين إلى اليسار.
- **مفتوح المصدر**، ولا يجمع أي بيانات.

## 📥 طريقة الاستخدام
1. نزّل **Source code (zip)** من الأسفل وفُكّ الضغط عنه.
2. صِل يد التحكم بالكابل، ثم انقر نقرًا مزدوجًا على **`Start Here.cmd`** واضغط **نعم**.
3. عند ظهور **اكتمل الإعداد**، افصل الكابل واضغط زر **PS** المستدير.

إن كنت لا تريد نافذة؟ انقر نقرًا مزدوجًا على **`Setup-PS3-Controller.cmd`** — الإعداد نفسه في نافذة نصية بسيطة (وهي الطريقة الأكثر اختبارًا).

## ⚠️ قيود معروفة (لماذا هذا إصدار تجريبي)
- **لم تُختبر النافذة على ويندوز بعد** — ويبقى `Setup-PS3-Controller.cmd` المُثبت هو الطريقة الموثوقة حاليًا.
- لأنه غير موقّع بشهادة مدفوعة، **قد يُحذّر SmartScreen أو مكافح الفيروسات** عند أول استخدام — اختر *Keep* أو *Allow*. البرنامج مفتوح المصدر؛ راجع [SECURITY.md](../SECURITY.md).
- مُوجَّه لعتاد Sony DualShock 3 الأصلي؛ وقد تختلف المقلّدة.

## 🙏 شكر وتقدير
بُني على DsHidMini وBthPS3 وViGEmBus من [Nefarius](https://github.com/nefarius)، ومشروع libusb-win32. غير تابع لشركة Sony أو Nefarius أو 8BitDo أو Microsoft.

</div>

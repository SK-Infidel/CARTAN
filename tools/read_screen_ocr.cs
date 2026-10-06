// tools/read_screen_ocr.cs
// Native Windows Desktop Screen Capture and Hardware-Accelerated WinRT OCR Utility for CARTAN / GeoMind
// Strict Zero-Mock: Authentically captures primary display via Win32 GDI and extracts on-screen text via Windows.Media.Ocr.

using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using Windows.Graphics.Imaging;
using Windows.Media.Ocr;
using Windows.Storage;

class Program {
    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr OpenWindowStation(string lpszWinStation, bool fInherit, uint dwDesiredAccess);
    [DllImport("user32.dll", SetLastError = true)]
    static extern bool SetProcessWindowStation(IntPtr hWinStation);
    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr OpenInputDesktop(uint dwFlags, bool fInherit, uint dwDesiredAccess);
    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr OpenDesktop(string lpszDesktop, uint dwFlags, bool fInherit, uint dwDesiredAccess);
    [DllImport("user32.dll", SetLastError = true)]
    static extern bool SetThreadDesktop(IntPtr hDesktop);
    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr GetDC(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError = true)]
    static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
    [DllImport("gdi32.dll", SetLastError = true)]
    static extern IntPtr CreateDC(string lpszDriver, string lpszDevice, string lpszOutput, IntPtr lpInitData);
    [DllImport("gdi32.dll", SetLastError = true)]
    static extern IntPtr CreateCompatibleDC(IntPtr hdc);
    [DllImport("gdi32.dll", SetLastError = true)]
    static extern IntPtr CreateCompatibleBitmap(IntPtr hdc, int nWidth, int nHeight);
    [DllImport("gdi32.dll", SetLastError = true)]
    static extern IntPtr SelectObject(IntPtr hdc, IntPtr hgdiobj);
    [DllImport("gdi32.dll", SetLastError = true)]
    static extern bool BitBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, int dwRop);
    [DllImport("gdi32.dll", SetLastError = true)]
    static extern bool DeleteDC(IntPtr hdc);
    [DllImport("gdi32.dll", SetLastError = true)]
    static extern bool DeleteObject(IntPtr hObject);
    [DllImport("user32.dll")]
    static extern int GetSystemMetrics(int nIndex);
    [DllImport("user32.dll")]
    static extern bool SetProcessDPIAware();

    const int SRCCOPY = 0x00CC0020;
    const uint MAXIMUM_ALLOWED = 0x02000000;

    static void AttachInteractiveSession() {
        try {
            IntPtr hwinsta = OpenWindowStation("winsta0", false, MAXIMUM_ALLOWED);
            if (hwinsta != IntPtr.Zero) {
                SetProcessWindowStation(hwinsta);
            }
            IntPtr hdesk = OpenInputDesktop(0, false, MAXIMUM_ALLOWED);
            if (hdesk == IntPtr.Zero) {
                hdesk = OpenDesktop("default", 0, false, MAXIMUM_ALLOWED);
            }
            if (hdesk != IntPtr.Zero) {
                SetThreadDesktop(hdesk);
            }
        } catch {
            // Ignore if already attached
        }
    }

    static Bitmap CapturePrimaryDisplay() {
        AttachInteractiveSession();
        int w = GetSystemMetrics(0);
        int h = GetSystemMetrics(1);
        if (w <= 0 || h <= 0) {
            w = 1920; h = 1080;
        }

        bool isCreateDC = false;
        IntPtr hdcScreen = GetDC(IntPtr.Zero);
        if (hdcScreen == IntPtr.Zero) {
            hdcScreen = CreateDC("DISPLAY", null, null, IntPtr.Zero);
            isCreateDC = true;
        }
        if (hdcScreen == IntPtr.Zero) {
            return null;
        }

        IntPtr hdcMem = CreateCompatibleDC(hdcScreen);
        IntPtr hbm = CreateCompatibleBitmap(hdcScreen, w, h);
        IntPtr hbmOld = SelectObject(hdcMem, hbm);

        bool success = BitBlt(hdcMem, 0, 0, w, h, hdcScreen, 0, 0, SRCCOPY);
        Bitmap bmp = null;
        if (success) {
            bmp = Image.FromHbitmap(hbm);
        }

        SelectObject(hdcMem, hbmOld);
        DeleteObject(hbm);
        DeleteDC(hdcMem);
        if (isCreateDC) {
            DeleteDC(hdcScreen);
        } else {
            ReleaseDC(IntPtr.Zero, hdcScreen);
        }

        return bmp;
    }

    static int Main(string[] args) {
        try {
            SetProcessDPIAware();
        } catch { }

        int maxLines = 100;
        if (args.Length > 0) {
            int.TryParse(args[0], out maxLines);
            if (maxLines <= 0) maxLines = 100;
        }

        string tmpPath = Path.Combine(Path.GetTempPath(), "geomind_screen_" + Guid.NewGuid().ToString("N") + ".png");
        try {
            using (Bitmap bmp = CapturePrimaryDisplay()) {
                if (bmp == null) {
                    Console.Error.WriteLine("Error: Failed to capture desktop screen.");
                    return 1;
                }
                bmp.Save(tmpPath, ImageFormat.Png);
            }

            var storageFile = StorageFile.GetFileFromPathAsync(tmpPath).AsTask().Result;
            using (var stream = storageFile.OpenAsync(FileAccessMode.Read).AsTask().Result) {
                var decoder = BitmapDecoder.CreateAsync(stream).AsTask().Result;
                var softwareBmp = decoder.GetSoftwareBitmapAsync().AsTask().Result;
                var engine = OcrEngine.TryCreateFromUserProfileLanguages();
                if (engine == null) {
                    if (OcrEngine.AvailableRecognizerLanguages.Count > 0) {
                        engine = OcrEngine.TryCreateFromLanguage(OcrEngine.AvailableRecognizerLanguages[0]);
                    }
                }
                if (engine == null) {
                    Console.Error.WriteLine("Error: WinRT OCR engine unavailable on host.");
                    return 2;
                }

                var ocrResult = engine.RecognizeAsync(softwareBmp).AsTask().Result;
                if (ocrResult == null || ocrResult.Lines.Count == 0) {
                    Console.WriteLine("(No text detected on screen)");
                    return 0;
                }

                int count = 0;
                foreach (var line in ocrResult.Lines) {
                    if (!string.IsNullOrWhiteSpace(line.Text)) {
                        Console.WriteLine(line.Text);
                        count++;
                        if (count >= maxLines) {
                            if (ocrResult.Lines.Count > maxLines) {
                                Console.WriteLine("[... " + (ocrResult.Lines.Count - maxLines) + " more lines truncated ...]");
                            }
                            break;
                        }
                    }
                }
            }
            return 0;
        } catch (Exception ex) {
            Console.Error.WriteLine("Error during screen OCR: " + ex.Message);
            return 3;
        } finally {
            try {
                if (File.Exists(tmpPath)) {
                    File.Delete(tmpPath);
                }
            } catch { }
        }
    }
}

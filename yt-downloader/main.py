"""
main.py
Entry point utama untuk aplikasi YouTube Audio Downloader.

Cara menjalankan:
    python main.py

Persyaratan:
    - Python 3.8+
    - PyQt5 (pip install PyQt5)
    - yt-dlp (pip install yt-dlp)
    - FFmpeg (install di sistem)
"""

import sys
import os

# Tambahkan direktori project ke Python path
project_root = os.path.dirname(os.path.abspath(__file__))
if project_root not in sys.path:
    sys.path.insert(0, project_root)


def check_dependencies() -> bool:
    """
    Cek apakah semua dependensi sudah terinstall.
    
    Returns:
        True jika semua dependensi tersedia, False jika tidak
    """
    missing = []
    
    try:
        import PyQt5
    except ImportError:
        missing.append("PyQt5 — install dengan: pip install PyQt5")
    
    try:
        import yt_dlp
    except ImportError:
        missing.append("yt-dlp — install dengan: pip install yt-dlp")
    
    if missing:
        print("❌ Dependensi berikut tidak ditemukan:")
        for dep in missing:
            print(f"   • {dep}")
        print("\nJalankan: pip install -r requirements.txt")
        return False
    
    return True


def main() -> None:
    """Fungsi utama untuk menjalankan aplikasi."""
    # Cek dependensi sebelum import PyQt5
    if not check_dependencies():
        sys.exit(1)
    
    from PyQt5.QtWidgets import QApplication
    from PyQt5.QtCore import Qt
    
    # Enable High DPI scaling
    QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
    QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)
    
    app = QApplication(sys.argv)
    app.setApplicationName("YouTube Audio Downloader")
    app.setApplicationVersion("1.0.0")
    app.setOrganizationName("yt-audio-downloader")
    
    # Import dan buat main window
    from ui.main_window import MainWindow
    
    window = MainWindow()
    window.show()
    
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()

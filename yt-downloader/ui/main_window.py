"""
ui/main_window.py
Main window PyQt5 untuk aplikasi yt-audio-downloader.
Menggunakan QThread untuk proses download agar UI tidak freeze.
"""

import os
import subprocess
import sys
from typing import Optional

from PyQt5.QtCore import (
    Qt, QThread, pyqtSignal, QObject, pyqtSlot
)
from PyQt5.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QLineEdit, QPushButton, QProgressBar,
    QFileDialog, QComboBox, QGroupBox, QFrame,
    QMessageBox, QSizePolicy, QApplication
)
from PyQt5.QtGui import QIcon, QClipboard

from src.downloader import AudioDownloader, DownloadError
from src.utils import format_speed, format_duration


class DownloadWorker(QObject):
    """
    Worker object untuk menjalankan download di thread terpisah.
    Menggunakan signal/slot untuk komunikasi thread-safe dengan UI.
    """
    
    # Signals
    progress_updated = pyqtSignal(dict)   # Data progress
    download_finished = pyqtSignal(str)   # Path file hasil
    download_error = pyqtSignal(str)      # Pesan error
    
    def __init__(self, url: str, output_path: str, audio_format: str = 'mp3'):
        super().__init__()
        self.url = url
        self.output_path = output_path
        self.audio_format = audio_format
        self._is_cancelled = False
    
    @pyqtSlot()
    def run(self) -> None:
        """Jalankan proses download di thread worker."""
        try:
            downloader = AudioDownloader(
                output_path=self.output_path,
                audio_format=self.audio_format
            )
            
            def progress_callback(data: dict) -> None:
                if not self._is_cancelled:
                    self.progress_updated.emit(data)
            
            output_file = downloader.download_audio(
                url=self.url,
                output_path=self.output_path,
                progress_callback=progress_callback
            )
            
            if not self._is_cancelled:
                self.download_finished.emit(output_file)
                
        except DownloadError as e:
            if not self._is_cancelled:
                self.download_error.emit(str(e))
        except Exception as e:
            if not self._is_cancelled:
                self.download_error.emit(f"Error tidak terduga: {str(e)}")
    
    def cancel(self) -> None:
        """Tandai download untuk dibatalkan."""
        self._is_cancelled = True


class MainWindow(QMainWindow):
    """
    Main window aplikasi YouTube Audio Downloader.
    
    Layout:
    - Header: Judul dan deskripsi
    - Input section: URL, output folder, format audio
    - Progress section: Progress bar dan status
    - Action section: Tombol Download/Cancel
    - Info section: Hasil download
    """
    
    def __init__(self):
        super().__init__()
        self._worker: Optional[DownloadWorker] = None
        self._thread: Optional[QThread] = None
        self._last_output_file: Optional[str] = None
        
        self._setup_ui()
        self._load_styles()
        self._connect_signals()
    
    def _setup_ui(self) -> None:
        """Setup semua komponen UI."""
        # Window properties
        self.setWindowTitle("YouTube Audio Downloader")
        self.setMinimumSize(600, 500)
        self.resize(680, 580)
        
        # Central widget
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QVBoxLayout(central)
        main_layout.setContentsMargins(24, 24, 24, 24)
        main_layout.setSpacing(16)
        
        # ── Header ──────────────────────────────────────────────
        header = QWidget()
        header_layout = QVBoxLayout(header)
        header_layout.setContentsMargins(0, 0, 0, 0)
        header_layout.setSpacing(4)
        
        self.title_label = QLabel("🎵 YouTube Audio Downloader")
        self.title_label.setObjectName("title_label")
        
        self.subtitle_label = QLabel("Unduh audio dari YouTube dan konversi ke MP3 kualitas tinggi")
        self.subtitle_label.setObjectName("subtitle_label")
        
        header_layout.addWidget(self.title_label)
        header_layout.addWidget(self.subtitle_label)
        main_layout.addWidget(header)
        
        # Separator
        sep = QFrame()
        sep.setFrameShape(QFrame.HLine)
        sep.setFrameShadow(QFrame.Sunken)
        main_layout.addWidget(sep)
        
        # ── Input Section ────────────────────────────────────────
        input_group = QGroupBox("Input")
        input_layout = QVBoxLayout(input_group)
        input_layout.setSpacing(12)
        
        # URL Input
        url_label = QLabel("URL YouTube:")
        url_label.setObjectName("section_label")
        
        url_row = QHBoxLayout()
        self.url_input = QLineEdit()
        self.url_input.setPlaceholderText(
            "Paste URL YouTube di sini... (contoh: https://youtu.be/dQw4w9WgXcQ)"
        )
        self.url_input.setClearButtonEnabled(True)
        
        self.paste_btn = QPushButton("📋 Paste")
        self.paste_btn.setObjectName("browse_btn")
        self.paste_btn.setFixedWidth(80)
        self.paste_btn.setToolTip("Paste dari clipboard")
        
        url_row.addWidget(self.url_input)
        url_row.addWidget(self.paste_btn)
        
        # Output folder
        folder_label = QLabel("Folder Output:")
        folder_label.setObjectName("section_label")
        
        folder_row = QHBoxLayout()
        default_downloads = os.path.join(os.path.expanduser("~"), "yt-audio-downloader", "downloads")
        
        self.folder_input = QLineEdit()
        self.folder_input.setText(default_downloads)
        self.folder_input.setReadOnly(True)
        self.folder_input.setToolTip("Folder tempat file MP3 disimpan")
        
        self.browse_btn = QPushButton("📁 Browse")
        self.browse_btn.setObjectName("browse_btn")
        self.browse_btn.setFixedWidth(90)
        
        folder_row.addWidget(self.folder_input)
        folder_row.addWidget(self.browse_btn)
        
        # Format row
        format_row = QHBoxLayout()
        format_label = QLabel("Format Audio:")
        format_label.setObjectName("section_label")
        
        self.format_combo = QComboBox()
        self.format_combo.addItems(['MP3 (320kbps)', 'AAC', 'OPUS', 'M4A', 'FLAC'])
        self.format_combo.setFixedWidth(160)
        self.format_combo.setToolTip("Pilih format audio output")
        
        format_row.addWidget(format_label)
        format_row.addWidget(self.format_combo)
        format_row.addStretch()
        
        input_layout.addWidget(url_label)
        input_layout.addLayout(url_row)
        input_layout.addWidget(folder_label)
        input_layout.addLayout(folder_row)
        input_layout.addLayout(format_row)
        
        main_layout.addWidget(input_group)
        
        # ── Progress Section ─────────────────────────────────────
        progress_group = QGroupBox("Progress")
        progress_layout = QVBoxLayout(progress_group)
        progress_layout.setSpacing(8)
        
        self.progress_bar = QProgressBar()
        self.progress_bar.setValue(0)
        self.progress_bar.setTextVisible(False)
        self.progress_bar.setFixedHeight(12)
        
        progress_info_row = QHBoxLayout()
        self.progress_pct_label = QLabel("0%")
        self.progress_pct_label.setFixedWidth(45)
        
        self.speed_label = QLabel("")
        self.speed_label.setAlignment(Qt.AlignRight)
        
        progress_info_row.addWidget(self.progress_pct_label)
        progress_info_row.addStretch()
        progress_info_row.addWidget(self.speed_label)
        
        self.status_label = QLabel("Siap untuk download")
        self.status_label.setObjectName("status_label")
        self.status_label.setWordWrap(True)
        
        progress_layout.addWidget(self.progress_bar)
        progress_layout.addLayout(progress_info_row)
        progress_layout.addWidget(self.status_label)
        
        main_layout.addWidget(progress_group)
        
        # ── Action Buttons ───────────────────────────────────────
        btn_row = QHBoxLayout()
        btn_row.setSpacing(12)
        
        self.download_btn = QPushButton("⬇️  Download MP3")
        self.download_btn.setObjectName("download_btn")
        
        self.cancel_btn = QPushButton("✖ Batalkan")
        self.cancel_btn.setObjectName("cancel_btn")
        self.cancel_btn.setVisible(False)
        
        self.open_folder_btn = QPushButton("📂 Buka Folder")
        self.open_folder_btn.setObjectName("open_folder_btn")
        self.open_folder_btn.setVisible(False)
        self.open_folder_btn.setFixedWidth(130)
        
        btn_row.addWidget(self.download_btn)
        btn_row.addWidget(self.cancel_btn)
        btn_row.addWidget(self.open_folder_btn)
        
        main_layout.addLayout(btn_row)
        main_layout.addStretch()
    
    def _load_styles(self) -> None:
        """Load stylesheet QSS dari file."""
        style_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            'ui', 'styles.qss'
        )
        
        if os.path.exists(style_path):
            with open(style_path, 'r') as f:
                self.setStyleSheet(f.read())
    
    def _connect_signals(self) -> None:
        """Hubungkan semua signal ke slot handler."""
        self.download_btn.clicked.connect(self._on_download_clicked)
        self.cancel_btn.clicked.connect(self._on_cancel_clicked)
        self.browse_btn.clicked.connect(self._on_browse_clicked)
        self.paste_btn.clicked.connect(self._on_paste_clicked)
        self.open_folder_btn.clicked.connect(self._on_open_folder_clicked)
        self.url_input.returnPressed.connect(self._on_download_clicked)
    
    # ── Event Handlers ───────────────────────────────────────────
    
    def _on_paste_clicked(self) -> None:
        """Paste URL dari clipboard."""
        clipboard = QApplication.clipboard()
        text = clipboard.text().strip()
        if text:
            self.url_input.setText(text)
    
    def _on_browse_clicked(self) -> None:
        """Buka dialog pilih folder output."""
        current = self.folder_input.text()
        if not os.path.exists(current):
            current = os.path.expanduser("~")
        
        folder = QFileDialog.getExistingDirectory(
            self,
            "Pilih Folder Output",
            current,
            QFileDialog.ShowDirsOnly
        )
        
        if folder:
            self.folder_input.setText(folder)
    
    def _on_download_clicked(self) -> None:
        """Mulai proses download."""
        url = self.url_input.text().strip()
        
        if not url:
            self._set_status("⚠️ Masukkan URL YouTube terlebih dahulu", "warning")
            self.url_input.setFocus()
            return
        
        # Validasi URL
        from src.downloader import AudioDownloader
        downloader = AudioDownloader()
        if not downloader.validate_url(url):
            self._set_status("❌ URL tidak valid. Pastikan URL dari YouTube.", "error")
            return
        
        output_path = self.folder_input.text()
        audio_format = self._get_selected_format()
        
        # Reset UI
        self._set_downloading_state(True)
        self.progress_bar.setValue(0)
        self.progress_pct_label.setText("0%")
        self.speed_label.setText("")
        self.open_folder_btn.setVisible(False)
        self._set_status("⏳ Memulai download...", "info")
        
        # Setup thread
        self._thread = QThread()
        self._worker = DownloadWorker(url, output_path, audio_format)
        self._worker.moveToThread(self._thread)
        
        # Connect signals
        self._thread.started.connect(self._worker.run)
        self._worker.progress_updated.connect(self._on_progress_updated)
        self._worker.download_finished.connect(self._on_download_finished)
        self._worker.download_error.connect(self._on_download_error)
        self._worker.download_finished.connect(self._thread.quit)
        self._worker.download_error.connect(self._thread.quit)
        self._thread.finished.connect(self._thread.deleteLater)
        
        self._thread.start()
    
    def _on_cancel_clicked(self) -> None:
        """Batalkan download yang sedang berjalan."""
        if self._worker:
            self._worker.cancel()
        if self._thread and self._thread.isRunning():
            self._thread.quit()
            self._thread.wait(3000)
        
        self._set_downloading_state(False)
        self.progress_bar.setValue(0)
        self.progress_pct_label.setText("0%")
        self.speed_label.setText("")
        self._set_status("⏹️ Download dibatalkan", "warning")
    
    @pyqtSlot(dict)
    def _on_progress_updated(self, data: dict) -> None:
        """Update UI berdasarkan data progress dari worker."""
        status = data.get('status', '')
        percentage = data.get('percentage', 0)
        speed = data.get('speed', 0)
        
        self.progress_bar.setValue(int(percentage))
        self.progress_pct_label.setText(f"{percentage:.0f}%")
        
        if speed:
            self.speed_label.setText(format_speed(speed))
        
        if status == 'downloading':
            eta = data.get('eta', 0)
            eta_str = f" • ETA: {eta}s" if eta else ""
            self._set_status(f"⬇️  Mengunduh... {percentage:.1f}%{eta_str}", "info")
        elif status == 'converting':
            self.speed_label.setText("")
            self._set_status("🔄 Mengkonversi ke MP3...", "info")
    
    @pyqtSlot(str)
    def _on_download_finished(self, output_file: str) -> None:
        """Handle event ketika download selesai."""
        self._last_output_file = output_file
        self._set_downloading_state(False)
        self.progress_bar.setValue(100)
        self.progress_pct_label.setText("100%")
        self.speed_label.setText("")
        
        filename = os.path.basename(output_file)
        self._set_status(f"✅ Selesai! Disimpan: {filename}", "success")
        self.open_folder_btn.setVisible(True)
    
    @pyqtSlot(str)
    def _on_download_error(self, error_msg: str) -> None:
        """Handle event ketika terjadi error download."""
        self._set_downloading_state(False)
        self.progress_bar.setValue(0)
        self.progress_pct_label.setText("0%")
        self.speed_label.setText("")
        self._set_status(f"❌ {error_msg}", "error")
    
    def _on_open_folder_clicked(self) -> None:
        """Buka folder output di file manager."""
        folder = self.folder_input.text()
        if os.path.exists(folder):
            if sys.platform == 'linux':
                subprocess.Popen(['xdg-open', folder])
            elif sys.platform == 'darwin':
                subprocess.Popen(['open', folder])
            elif sys.platform == 'win32':
                os.startfile(folder)
    
    # ── Helper Methods ───────────────────────────────────────────
    
    def _set_downloading_state(self, is_downloading: bool) -> None:
        """Toggle state UI antara sedang download dan idle."""
        self.download_btn.setVisible(not is_downloading)
        self.cancel_btn.setVisible(is_downloading)
        self.url_input.setEnabled(not is_downloading)
        self.browse_btn.setEnabled(not is_downloading)
        self.format_combo.setEnabled(not is_downloading)
        self.paste_btn.setEnabled(not is_downloading)
    
    def _set_status(self, message: str, status_type: str = "info") -> None:
        """
        Update label status dengan pesan dan tipe visual.
        
        Args:
            message: Pesan status
            status_type: 'info', 'success', 'warning', 'error'
        """
        self.status_label.setText(message)
        
        color_map = {
            'info': '#cdd6f4',
            'success': '#a6e3a1',
            'warning': '#f9e2af',
            'error': '#f38ba8',
        }
        
        color = color_map.get(status_type, '#cdd6f4')
        self.status_label.setStyleSheet(f"color: {color};")
    
    def _get_selected_format(self) -> str:
        """Ambil format audio yang dipilih dari combobox."""
        format_map = {
            0: 'mp3',
            1: 'aac',
            2: 'opus',
            3: 'm4a',
            4: 'flac',
        }
        return format_map.get(self.format_combo.currentIndex(), 'mp3')
    
    def closeEvent(self, event) -> None:
        """Handle event ketika window ditutup."""
        if self._thread and self._thread.isRunning():
            reply = QMessageBox.question(
                self,
                "Download Berjalan",
                "Ada download yang sedang berjalan. Batalkan dan keluar?",
                QMessageBox.Yes | QMessageBox.No,
                QMessageBox.No
            )
            
            if reply == QMessageBox.Yes:
                if self._worker:
                    self._worker.cancel()
                self._thread.quit()
                self._thread.wait(3000)
                event.accept()
            else:
                event.ignore()
        else:
            event.accept()

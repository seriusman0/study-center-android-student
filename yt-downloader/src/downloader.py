"""
src/downloader.py
Module utama untuk download audio dari YouTube menggunakan yt-dlp.
"""

import os
import re
from typing import Callable, Dict, Any, Optional

try:
    import yt_dlp
    YT_DLP_AVAILABLE = True
except ImportError:
    YT_DLP_AVAILABLE = False

from src.utils import validate_url, sanitize_filename


class DownloadError(Exception):
    """Exception kustom untuk error download."""
    pass


class AudioDownloader:
    """
    Class untuk mendownload audio dari YouTube dan mengkonversinya ke MP3.
    
    Attributes:
        output_path: Direktori output untuk file hasil download
        audio_quality: Kualitas audio (0=terbaik, 9=terburuk untuk VBR)
        audio_format: Format audio output ('mp3', 'aac', 'opus', dll)
    """
    
    def __init__(
        self,
        output_path: str = './downloads',
        audio_quality: str = '0',
        audio_format: str = 'mp3'
    ):
        """
        Inisialisasi AudioDownloader.
        
        Args:
            output_path: Path direktori output
            audio_quality: Kualitas audio VBR (0=terbaik)
            audio_format: Format audio output
        """
        self.output_path = output_path
        self.audio_quality = audio_quality
        self.audio_format = audio_format
        
        if not YT_DLP_AVAILABLE:
            raise ImportError("yt-dlp tidak terinstall. Jalankan: pip install yt-dlp")
    
    def validate_url(self, url: str) -> bool:
        """
        Validasi URL YouTube.
        
        Args:
            url: URL yang akan divalidasi
            
        Returns:
            True jika valid, False jika tidak
        """
        return validate_url(url)
    
    def get_metadata(self, url: str) -> Dict[str, Any]:
        """
        Ambil metadata video dari URL.
        
        Args:
            url: URL YouTube
            
        Returns:
            Dictionary berisi metadata (title, duration, thumbnail, uploader)
            
        Raises:
            DownloadError: Jika gagal mengambil metadata
        """
        if not self.validate_url(url):
            raise DownloadError("URL tidak valid atau tidak didukung")
        
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
        }
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                
                if info is None:
                    raise DownloadError("Gagal mengambil informasi video")
                
                return {
                    'title': info.get('title', 'Unknown'),
                    'duration': info.get('duration', 0),
                    'thumbnail': info.get('thumbnail', ''),
                    'uploader': info.get('uploader', 'Unknown'),
                    'view_count': info.get('view_count', 0),
                    'upload_date': info.get('upload_date', ''),
                    'is_playlist': info.get('_type') == 'playlist',
                    'entries': info.get('entries', []) if info.get('_type') == 'playlist' else [],
                }
        except yt_dlp.utils.DownloadError as e:
            error_msg = str(e)
            if 'Private video' in error_msg:
                raise DownloadError("Video bersifat privat dan tidak dapat diakses")
            elif 'Video unavailable' in error_msg:
                raise DownloadError("Video tidak tersedia atau telah dihapus")
            elif 'Sign in' in error_msg:
                raise DownloadError("Video membutuhkan login untuk diakses")
            else:
                raise DownloadError(f"Gagal mengambil metadata: {error_msg}")
        except Exception as e:
            raise DownloadError(f"Error tidak terduga: {str(e)}")
    
    def download_audio(
        self,
        url: str,
        output_path: Optional[str] = None,
        progress_callback: Optional[Callable[[Dict[str, Any]], None]] = None
    ) -> str:
        """
        Download audio dari URL YouTube dan konversi ke MP3.
        
        Args:
            url: URL YouTube
            output_path: Path direktori output (opsional, gunakan self.output_path jika None)
            progress_callback: Callback function yang dipanggil dengan data progress
                               Format: {'percentage': float, 'speed': float, 'eta': int, 'status': str}
            
        Returns:
            Path file MP3 yang berhasil didownload
            
        Raises:
            DownloadError: Jika terjadi error saat download
        """
        if not self.validate_url(url):
            raise DownloadError("URL tidak valid atau tidak didukung")
        
        save_path = output_path or self.output_path
        os.makedirs(save_path, exist_ok=True)
        
        def progress_hook(d: Dict[str, Any]) -> None:
            """Hook internal untuk tracking progress yt-dlp."""
            if progress_callback is None:
                return
            
            status = d.get('status', '')
            
            if status == 'downloading':
                downloaded = d.get('downloaded_bytes', 0)
                total = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
                
                percentage = 0.0
                if total and total > 0:
                    percentage = (downloaded / total) * 100
                
                progress_callback({
                    'status': 'downloading',
                    'percentage': percentage,
                    'speed': d.get('speed', 0),
                    'eta': d.get('eta', 0),
                    'downloaded_bytes': downloaded,
                    'total_bytes': total,
                })
            
            elif status == 'finished':
                progress_callback({
                    'status': 'converting',
                    'percentage': 99.0,
                    'speed': 0,
                    'eta': 0,
                    'message': 'Mengkonversi ke MP3...',
                })
            
            elif status == 'error':
                progress_callback({
                    'status': 'error',
                    'percentage': 0.0,
                    'speed': 0,
                    'eta': 0,
                    'message': 'Terjadi error saat download',
                })
        
        ydl_opts = {
            'format': 'bestaudio/best',
            'outtmpl': os.path.join(save_path, '%(title)s.%(ext)s'),
            'progress_hooks': [progress_hook],
            'quiet': True,
            'no_warnings': False,
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': self.audio_format,
                'preferredquality': self.audio_quality,
            }],
            'postprocessor_args': {
                'FFmpegExtractAudio': ['-q:a', '0'],
            },
        }
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=True)
                
                if info is None:
                    raise DownloadError("Gagal mengambil informasi video")
                
                # Dapatkan path file output
                title = sanitize_filename(info.get('title', 'audio'))
                output_file = os.path.join(save_path, f"{title}.{self.audio_format}")
                
                if progress_callback:
                    progress_callback({
                        'status': 'completed',
                        'percentage': 100.0,
                        'speed': 0,
                        'eta': 0,
                        'message': f'Selesai: {title}.{self.audio_format}',
                        'output_file': output_file,
                    })
                
                return output_file
                
        except yt_dlp.utils.DownloadError as e:
            error_msg = str(e)
            
            if 'ffmpeg' in error_msg.lower() or 'ffprobe' in error_msg.lower():
                raise DownloadError(
                    "FFmpeg tidak ditemukan. Silakan install FFmpeg:\n"
                    "Ubuntu/Debian: sudo apt install ffmpeg\n"
                    "Windows: Download dari https://ffmpeg.org"
                )
            elif 'Network' in error_msg or 'Connection' in error_msg or 'Unable to download' in error_msg:
                raise DownloadError(
                    "Gagal terhubung ke server. Periksa koneksi internet Anda."
                )
            elif 'Private video' in error_msg:
                raise DownloadError("Video bersifat privat dan tidak dapat diakses")
            elif 'Video unavailable' in error_msg:
                raise DownloadError("Video tidak tersedia atau telah dihapus")
            else:
                raise DownloadError(f"Error download: {error_msg}")
        
        except Exception as e:
            raise DownloadError(f"Error tidak terduga: {str(e)}")

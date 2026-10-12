"""
src/utils.py
Helper functions untuk validasi URL dan utilitas umum.
"""

import re
from typing import Optional


YOUTUBE_URL_PATTERNS = [
    r'(https?://)?(www\.)?youtube\.com/watch\?v=[\w-]+',
    r'(https?://)?youtu\.be/[\w-]+',
    r'(https?://)?(www\.)?youtube\.com/playlist\?list=[\w-]+',
    r'(https?://)?(www\.)?youtube\.com/shorts/[\w-]+',
    r'(https?://)?(m\.)?youtube\.com/watch\?v=[\w-]+',
]


def validate_url(url: str) -> bool:
    """
    Validasi apakah URL adalah URL YouTube yang valid.
    
    Args:
        url: String URL yang akan divalidasi
        
    Returns:
        True jika URL valid, False jika tidak
    """
    if not url or not url.strip():
        return False
    
    url = url.strip()
    
    for pattern in YOUTUBE_URL_PATTERNS:
        if re.search(pattern, url):
            return True
    
    return False


def sanitize_filename(filename: str) -> str:
    """
    Membersihkan nama file dari karakter yang tidak valid.
    
    Args:
        filename: Nama file yang akan dibersihkan
        
    Returns:
        Nama file yang sudah dibersihkan
    """
    # Hapus karakter yang tidak valid untuk nama file
    invalid_chars = r'<>:"/\\|?*'
    for char in invalid_chars:
        filename = filename.replace(char, '_')
    
    # Batasi panjang nama file
    if len(filename) > 200:
        filename = filename[:200]
    
    return filename.strip()


def format_size(bytes_size: Optional[int]) -> str:
    """
    Format ukuran byte menjadi string yang mudah dibaca.
    
    Args:
        bytes_size: Ukuran dalam byte
        
    Returns:
        String format ukuran (contoh: '4.2 MB')
    """
    if bytes_size is None:
        return 'Unknown'
    
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes_size < 1024.0:
            return f'{bytes_size:.1f} {unit}'
        bytes_size /= 1024.0
    
    return f'{bytes_size:.1f} TB'


def format_duration(seconds: Optional[int]) -> str:
    """
    Format durasi detik menjadi format MM:SS atau HH:MM:SS.
    
    Args:
        seconds: Durasi dalam detik
        
    Returns:
        String format durasi
    """
    if seconds is None:
        return 'Unknown'
    
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    
    if hours > 0:
        return f'{hours:02d}:{minutes:02d}:{secs:02d}'
    return f'{minutes:02d}:{secs:02d}'


def format_speed(bytes_per_sec: Optional[float]) -> str:
    """
    Format kecepatan download menjadi string yang mudah dibaca.
    
    Args:
        bytes_per_sec: Kecepatan dalam byte per detik
        
    Returns:
        String format kecepatan (contoh: '1.2 MB/s')
    """
    if bytes_per_sec is None:
        return ''
    
    return f'{format_size(int(bytes_per_sec))}/s'

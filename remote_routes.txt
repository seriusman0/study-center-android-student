<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\PublicJurnalController;
use App\Http\Controllers\Web\HomeController;
use App\Http\Controllers\Web\BlogWebController;
use App\Http\Controllers\Web\CabangWebController;
use App\Http\Controllers\Web\AuthWebController;
use App\Http\Controllers\Web\ProfileWebController;
use App\Http\Controllers\Web\CvWebController;
use App\Http\Controllers\Web\CommentWebController;
use App\Http\Controllers\Web\Admin\AdminController;
use App\Http\Controllers\Web\Admin\LeaderboardController;
use App\Http\Controllers\Web\Admin\JurnalPhotoScanController;
use App\Http\Controllers\Web\Admin\AdminJurnalHubController;
use App\Http\Controllers\Web\Admin\MataPelajaranController;
use App\Http\Controllers\Web\Admin\RoleAdminController;
use App\Http\Controllers\Web\Admin\PermissionAdminController;
use App\Http\Controllers\Web\Admin\NameTagController;
use App\Http\Controllers\Web\PresensiController;
use App\Http\Controllers\Web\JurnalController;
use App\Http\Controllers\Web\Admin\JurnalBibleScheduleController;
use App\Http\Controllers\Web\Admin\JurnalWeeklyVerseController;
use App\Http\Controllers\Web\Admin\JurnalLifeItemController;
use App\Http\Controllers\Web\Admin\JurnalReportController;
use App\Http\Controllers\Web\Admin\JurnalBulkController;
use App\Http\Controllers\Web\Admin\JurnalOfflineTemplateController;
use App\Http\Controllers\Web\Admin\KelasMasterController;
use App\Http\Controllers\Web\MentorPresensiController;
use App\Http\Controllers\Web\Admin\MentorPresensiAdminController;
use App\Http\Controllers\Web\Admin\CertificateTemplateController;
use App\Http\Controllers\Web\Admin\IssuedCertificateController;
use App\Http\Controllers\Web\Admin\PendaftaranAdminController;
use App\Http\Controllers\Web\PendaftaranController;
use App\Http\Controllers\Web\BerandaController;
use App\Http\Controllers\Web\Admin\AnnouncementController;
use App\Http\Controllers\Web\AnnouncementDismissController;

// Public pages
Route::get('/', [HomeController::class, 'index'])->name('home');

// Public Jurnal API for Scanner
Route::post('/public-jurnal/scan', [PublicJurnalController::class, 'scan'])->name('public-jurnal.scan');
Route::post('/public-jurnal/save', [PublicJurnalController::class, 'save'])->name('public-jurnal.save');

Route::get('/blog', [BlogWebController::class, 'index'])->name('blog.index');
Route::get('/cabang', [CabangWebController::class, 'index'])->name('cabang.index');
Route::get('/cabang/{slug}', [CabangWebController::class, 'show'])->name('cabang.show');

// Student registration (public)
Route::get('/pendaftaran', [PendaftaranController::class, 'pilihCabang'])->name('pendaftaran.pilih-cabang');
// perbaikan/{token} MUST be before {cabang:slug} to avoid slug conflict
Route::get('/pendaftaran/perbaikan/{token}', [PendaftaranController::class, 'showUpdateForm'])->name('pendaftaran.update.form');
Route::post('/pendaftaran/perbaikan/{token}', [PendaftaranController::class, 'processUpdate'])->name('pendaftaran.update.store');
// Per-cabang multi-step flow
Route::get('/pendaftaran/{cabang:slug}', [PendaftaranController::class, 'showForm'])->name('pendaftaran.form');
Route::post('/pendaftaran/{cabang:slug}', [PendaftaranController::class, 'store'])->name('pendaftaran.store');
Route::get('/pendaftaran/{cabang:slug}/preview', [PendaftaranController::class, 'preview'])->name('pendaftaran.preview');
Route::post('/pendaftaran/{cabang:slug}/konfirmasi', [PendaftaranController::class, 'konfirmasi'])->name('pendaftaran.konfirmasi');
Route::get('/pendaftaran/{cabang:slug}/sukses', [PendaftaranController::class, 'sukses'])->name('pendaftaran.sukses');
Route::get('/pendaftaran/{cabang:slug}/kartu', [PendaftaranController::class, 'kartu'])->name('pendaftaran.kartu');
Route::get('/cek-pendaftaran/{username}', [PendaftaranController::class, 'cekStatus'])->name('pendaftaran.cek');

// Auth pages (guest only)
Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthWebController::class, 'loginForm'])->name('login');
    Route::post('/login', [AuthWebController::class, 'login']);
    Route::post('/login/fast', [AuthWebController::class, 'fastLogin'])->name('login.fast');
    Route::get('/daftar', [AuthWebController::class, 'pilihRegistrasi'])->name('register');
    Route::get('/daftar/tamu', [AuthWebController::class, 'registerForm'])->name('register.tamu');
    Route::post('/daftar/tamu', [AuthWebController::class, 'register']);
});
Route::post('/logout', [AuthWebController::class, 'logout'])->name('logout')->middleware('auth');

// Profile edit must be before wildcard /profil/{username}
Route::middleware('auth')->group(function () {
    Route::get('/profil/edit', [ProfileWebController::class, 'edit'])->name('profile.edit');
    Route::post('/profil/edit', [ProfileWebController::class, 'update'])->name('profile.update');
    Route::get('/cv/edit', [CvWebController::class, 'edit'])->name('cv.edit');
    Route::post('/cv/edit', [CvWebController::class, 'update'])->name('cv.update');
    Route::post('/admin/stop-impersonating', [AdminController::class, 'stopImpersonating'])->name('admin.stop-impersonating');
});

// Public profile routes (after static /profil/edit)
Route::get('/profil/{username}', [ProfileWebController::class, 'show'])->name('profile.show');
Route::get('/profil/{username}/cv', [CvWebController::class, 'show'])->name('cv.show');
Route::get('/profil/{username}/kartu-nama', [CvWebController::class, 'kartuNama'])->name('cv.kartu-nama');

// Staff-only blog management
Route::middleware(['auth', 'role:admin,fulltimer,mentor,student'])->group(function () {
    Route::get('/blog/tulis', [BlogWebController::class, 'create'])->name('blog.create');
    Route::post('/blog', [BlogWebController::class, 'store'])->name('blog.store');
    Route::post('/blog/upload-image', [BlogWebController::class, 'uploadImage'])->name('blog.upload-image');
    Route::get('/blog/{slug}/edit', [BlogWebController::class, 'edit'])->name('blog.edit');
    Route::post('/blog/{blog}', [BlogWebController::class, 'update'])->name('blog.update');
    Route::delete('/blog/{blog}', [BlogWebController::class, 'destroy'])->name('blog.destroy');
});

// Must be after static /blog/tulis and /blog/{slug}/edit
Route::get('/blog/{slug}', [BlogWebController::class, 'show'])->name('blog.show');

// Comments (auth)
Route::middleware('auth')->group(function () {
    Route::post('/blog/{blog}/comments', [CommentWebController::class, 'store'])->name('comment.store');
    Route::delete('/comments/{comment}', [CommentWebController::class, 'destroy'])->name('comment.destroy');
});

// Presensi (admin + mentor)
Route::middleware(['auth', 'role:admin,mentor'])->prefix('presensi')->name('presensi.')->group(function () {
    Route::get('/', [PresensiController::class, 'index'])->name('index');
    Route::get('/create', [PresensiController::class, 'create'])->name('create');
    Route::post('/', [PresensiController::class, 'store'])->name('store');
    Route::get('/api/students', [PresensiController::class, 'searchStudents'])->name('students.search');
    Route::get('/report', [PresensiController::class, 'report'])->name('report');
    Route::get('/{presensi}', [PresensiController::class, 'show'])->name('show');
    Route::get('/{presensi}/edit', [PresensiController::class, 'edit'])->name('edit');
    Route::put('/{presensi}', [PresensiController::class, 'update'])->name('update');
    Route::delete('/{presensi}', [PresensiController::class, 'destroy'])->name('destroy');
    Route::post('/{presensi}/scan', [PresensiController::class, 'scanStudent'])->name('scan');
});

// Admin panel — dashboard + read-only users list shared with mentor
Route::middleware(['auth', 'role:admin,mentor'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/', [AdminController::class, 'dashboard'])->name('dashboard');
    Route::get('/users', [AdminController::class, 'users'])->name('users');
    Route::get('/leaderboard', [LeaderboardController::class, 'index'])->name('leaderboard');

    Route::get('/jurnal/scan', [JurnalPhotoScanController::class, 'create'])->name('jurnal.scan.create');
    Route::post('/jurnal/scan', [JurnalPhotoScanController::class, 'upload'])->name('jurnal.scan.upload');
    Route::get('/jurnal/scan/{scan}/status', [JurnalPhotoScanController::class, 'status'])->name('jurnal.scan.status');
    Route::post('/jurnal/scan/confirm', [JurnalPhotoScanController::class, 'confirm'])->name('jurnal.scan.confirm');

    Route::get('/pendaftaran', [PendaftaranAdminController::class, 'index'])->name('pendaftaran.index');
    Route::get('/pendaftaran/{user}', [PendaftaranAdminController::class, 'show'])->name('pendaftaran.show');
    Route::patch('/pendaftaran/{user}/validasi', [PendaftaranAdminController::class, 'validasi'])->name('pendaftaran.validasi');
    Route::post('/pendaftaran/{user}/generate-update-link', [PendaftaranAdminController::class, 'generateUpdateLink'])->name('pendaftaran.generate-update-link');
});

Route::middleware(['auth', 'role:admin'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/beta-testers', [\App\Http\Controllers\Web\Admin\BetaTesterController::class, 'index'])->name('beta-testers.index');
    Route::put('/beta-testers/{tester}', [\App\Http\Controllers\Web\Admin\BetaTesterController::class, 'update'])->name('beta-testers.update');
    
    Route::get('/users/create', [AdminController::class, 'createUser'])->name('users.create');
    Route::post('/users', [AdminController::class, 'storeUser'])->name('users.store');
    Route::get('/users/{user}/edit', [AdminController::class, 'editUser'])->name('users.edit');
    Route::get('/users/qr-print-cabang', [AdminController::class, 'printQrCabang'])->name('users.qr-print-cabang');
    Route::get('/users/qr-download-all', [AdminController::class, 'downloadAllQrPdf'])->name('users.qr-download-all');
    Route::get('/users/{user}/qr-print', [AdminController::class, 'printQr'])->name('users.qr-print');
    Route::put('/users/{user}', [AdminController::class, 'updateUser'])->name('users.update');
    Route::post('/users/{user}/role', [AdminController::class, 'updateRole'])->name('users.role');
    Route::post('/users/{user}/toggle-active', [AdminController::class, 'toggleActive'])->name('users.toggle');
    Route::delete('/users/{user}', [AdminController::class, 'deleteUser'])->name('users.delete');
    Route::post('/users/{user}/impersonate', [AdminController::class, 'impersonateUser'])->name('users.impersonate');
    Route::get('/cabangs', [AdminController::class, 'cabangs'])->name('cabangs');
    Route::post('/cabangs', [AdminController::class, 'storeCabang'])->name('cabangs.store');
    Route::post('/cabangs/{cabang}', [AdminController::class, 'updateCabang'])->name('cabangs.update');
    Route::delete('/cabangs/{cabang}', [AdminController::class, 'deleteCabang'])->name('cabangs.delete');

    Route::get('/mata-pelajaran', [MataPelajaranController::class, 'index'])->name('mata-pelajaran');
    Route::post('/mata-pelajaran', [MataPelajaranController::class, 'store'])->name('mata-pelajaran.store');
    Route::post('/mata-pelajaran/{mataPelajaran}', [MataPelajaranController::class, 'update'])->name('mata-pelajaran.update');
    Route::post('/mata-pelajaran/{mataPelajaran}/toggle', [MataPelajaranController::class, 'toggleActive'])->name('mata-pelajaran.toggle');
    Route::delete('/mata-pelajaran/{mataPelajaran}', [MataPelajaranController::class, 'destroy'])->name('mata-pelajaran.destroy');
    Route::get('/blogs', [AdminController::class, 'blogs'])->name('blogs');
    Route::delete('/blogs/{blog}', [AdminController::class, 'deleteBlog'])->name('blogs.delete');

    Route::get('/roles', [RoleAdminController::class, 'index'])->name('roles');
    Route::post('/roles', [RoleAdminController::class, 'store'])->name('roles.store');
    Route::put('/roles/{role}', [RoleAdminController::class, 'update'])->name('roles.update');
    Route::post('/roles/{role}/permissions', [RoleAdminController::class, 'syncPermissions'])->name('roles.permissions');
    Route::delete('/roles/{role}', [RoleAdminController::class, 'destroy'])->name('roles.delete');

    Route::get('/nametags', [NameTagController::class, 'index'])->name('nametags');
    Route::post('/nametags/generate', [NameTagController::class, 'generate'])->name('nametags.generate');

    Route::prefix('nametag-templates')->name('nametag-templates.')->group(function () {
        Route::get('/', [\App\Http\Controllers\Web\Admin\NameTagTemplateController::class, 'index'])->name('index');
        Route::get('/{template}/edit', [\App\Http\Controllers\Web\Admin\NameTagTemplateController::class, 'edit'])->name('edit');
        Route::put('/{template}', [\App\Http\Controllers\Web\Admin\NameTagTemplateController::class, 'update'])->name('update');
        Route::post('/{template}/duplicate', [\App\Http\Controllers\Web\Admin\NameTagTemplateController::class, 'duplicate'])->name('duplicate');
        Route::delete('/{template}', [\App\Http\Controllers\Web\Admin\NameTagTemplateController::class, 'destroy'])->name('destroy');
        Route::post('/{template}/preview', [\App\Http\Controllers\Web\Admin\NameTagTemplateController::class, 'preview'])->name('preview');
    });

    Route::get('/permissions', [PermissionAdminController::class, 'index'])->name('permissions');
    Route::post('/permissions', [PermissionAdminController::class, 'store'])->name('permissions.store');
    Route::put('/permissions/{permission}', [PermissionAdminController::class, 'update'])->name('permissions.update');
    Route::delete('/permissions/{permission}', [PermissionAdminController::class, 'destroy'])->name('permissions.delete');

});

// Announcements (admin + fulltimer)
Route::middleware(['auth', 'role:admin,fulltimer'])->prefix('admin/announcements')->name('admin.announcements.')->group(function () {
    Route::get('/', [AnnouncementController::class, 'index'])->name('index');
    Route::get('/create', [AnnouncementController::class, 'create'])->name('create');
    Route::post('/', [AnnouncementController::class, 'store'])->name('store');
    Route::get('/{announcement}/edit', [AnnouncementController::class, 'edit'])->name('edit');
    Route::put('/{announcement}', [AnnouncementController::class, 'update'])->name('update');
    Route::delete('/{announcement}', [AnnouncementController::class, 'destroy'])->name('destroy');
    Route::post('/{announcement}/toggle', [AnnouncementController::class, 'toggle'])->name('toggle');
});

// Dismiss announcement (any authenticated user)
Route::middleware('auth')->post('/announcements/{id}/dismiss', [AnnouncementDismissController::class, 'dismiss'])->name('announcements.dismiss');

// Beranda (student + college + scholarship_teenager + mentor + prajurit)
Route::middleware(['auth', 'role:student,college,scholarship_teenager,mentor,prajurit'])->group(function () {
    Route::get('/beranda', [BerandaController::class, 'index'])->name('beranda');
});

// Laporan Jurnal (student + college + scholarship_teenager)
Route::middleware(['auth', 'role:student,college,scholarship_teenager'])->get('/laporan', [\App\Http\Controllers\Web\LaporanController::class, 'index'])->name('laporan');

// Jurnal (student-facing)
Route::middleware(['auth', 'role:student'])->prefix('jurnal')->name('jurnal.')->group(function () {
    Route::get('/', [JurnalController::class, 'index'])->name('index');
    Route::post('/toggle', [JurnalController::class, 'toggle'])->name('toggle');
    Route::post('/foto', [JurnalController::class, 'uploadFoto'])->name('foto.upload');
    Route::delete('/foto', [JurnalController::class, 'deleteFoto'])->name('foto.delete');
});

// Jurnal admin/mentor management
Route::middleware(['auth', 'role:admin,mentor'])->prefix('admin/jurnal')->name('admin.jurnal.')->group(function () {
    Route::get   ('life-items',                          [JurnalLifeItemController::class, 'index'])->name('life-items.index');
    Route::post  ('life-items',                          [JurnalLifeItemController::class, 'store'])->name('life-items.store');
    Route::post  ('life-items/assign-all',               [JurnalLifeItemController::class, 'assignAllToAllStudents'])->name('life-items.assign-all');
    Route::put   ('life-items/{item}',                   [JurnalLifeItemController::class, 'update'])->name('life-items.update');
    Route::delete('life-items/{item}',                   [JurnalLifeItemController::class, 'destroy'])->name('life-items.destroy');
    Route::get   ('students/{student}/life-items',       [JurnalLifeItemController::class, 'studentAssignments'])->name('life-items.student');
    Route::post  ('students/{student}/life-items',       [JurnalLifeItemController::class, 'syncStudent'])->name('life-items.sync');
    Route::post  ('students/{student}/reset-defaults',   [JurnalLifeItemController::class, 'resetToDefaults'])->name('life-items.reset-defaults');

    Route::get('reports',                                [JurnalReportController::class, 'index'])->name('reports.index');
    Route::get('reports/{student}',                      [JurnalReportController::class, 'show'])->name('reports.show');
    Route::get('reports/{student}/export',               [JurnalReportController::class, 'export'])->name('reports.export');
    Route::get('reports/{student}/print',                [JurnalReportController::class, 'printPdf'])->name('reports.print');

    Route::get('/bulk', [JurnalBulkController::class, 'create'])->name('bulk.create');
    Route::post('/bulk', [JurnalBulkController::class, 'store'])->name('bulk.store');

    Route::get('/offline-templates', [JurnalOfflineTemplateController::class, 'index'])->name('offline-templates.index');
    Route::post('/offline-templates', [JurnalOfflineTemplateController::class, 'store'])->name('offline-templates.store');
    Route::get('/offline-templates/{template}/download', [JurnalOfflineTemplateController::class, 'download'])->name('offline-templates.download');
    Route::delete('/offline-templates/{template}', [JurnalOfflineTemplateController::class, 'destroy'])->name('offline-templates.destroy');

    Route::get('/bible-schedules', [JurnalBibleScheduleController::class, 'index'])->name('bible-schedules.index');
    Route::post('/bible-schedules', [JurnalBibleScheduleController::class, 'store'])->name('bible-schedules.store');
    Route::post('/bible-schedules/bulk', [JurnalBibleScheduleController::class, 'bulkStore'])->name('bible-schedules.bulk');
    Route::put('/bible-schedules/{bibleSchedule}', [JurnalBibleScheduleController::class, 'update'])->name('bible-schedules.update');
    Route::delete('/bible-schedules/{bibleSchedule}', [JurnalBibleScheduleController::class, 'destroy'])->name('bible-schedules.destroy');

    Route::get('/weekly-verses', [JurnalWeeklyVerseController::class, 'index'])->name('weekly-verses.index');
    Route::post('/weekly-verses', [JurnalWeeklyVerseController::class, 'store'])->name('weekly-verses.store');
    Route::put('/weekly-verses/{weeklyVerse}', [JurnalWeeklyVerseController::class, 'update'])->name('weekly-verses.update');
    Route::delete('/weekly-verses/{weeklyVerse}', [JurnalWeeklyVerseController::class, 'destroy'])->name('weekly-verses.destroy');
});

// Mentor self-attendance
Route::middleware(['auth', 'role:mentor'])->prefix('mentor/presensi')->name('mentor-presensi.')->group(function () {
    Route::get('/',                [MentorPresensiController::class, 'index'])->name('index');
    Route::get('/create',          [MentorPresensiController::class, 'create'])->name('create');
    Route::post('/',               [MentorPresensiController::class, 'store'])->name('store');
    Route::get('/{presensi}/edit', [MentorPresensiController::class, 'edit'])->name('edit');
    Route::put('/{presensi}',      [MentorPresensiController::class, 'update'])->name('update');
    Route::delete('/{presensi}',   [MentorPresensiController::class, 'destroy'])->name('destroy');
    Route::get('/api/kelas',       [MentorPresensiController::class, 'searchKelas'])->name('kelas.search');
});

Route::middleware(['auth', 'role:mentor'])->prefix('mentor')->name('mentor.')->group(function () {
    Route::get('/jurnal', [JurnalReportController::class, 'index'])->name('jurnal.index');
    Route::get('/jurnal/{student}', [JurnalReportController::class, 'show'])->name('jurnal.show');
    Route::get('/jurnal/{student}/export', [JurnalReportController::class, 'export'])->name('jurnal.export');

    Route::get('/kelas-master', [KelasMasterController::class, 'index'])->name('kelas-master.index');
    Route::post('/kelas-master', [KelasMasterController::class, 'store'])->name('kelas-master.store');
    Route::put('/kelas-master/{kelas}', [KelasMasterController::class, 'update'])->name('kelas-master.update');
    Route::delete('/kelas-master/{kelas}', [KelasMasterController::class, 'destroy'])->name('kelas-master.destroy');
});

// Shared kelas master search (for /presensi/create form)
Route::middleware(['auth', 'role:admin,mentor'])
    ->get('/presensi/api/kelas-master', [MentorPresensiController::class, 'searchKelas'])
    ->name('presensi.kelas-master.search');

// Kelas master (admin+mentor full CRUD)
Route::middleware(['auth', 'role:admin,mentor'])->prefix('admin')->name('admin.')->group(function () {
    Route::get   ('/kelas-master',          [KelasMasterController::class, 'index'])->name('kelas-master.index');
    Route::post  ('/kelas-master',          [KelasMasterController::class, 'store'])->name('kelas-master.store');
    Route::put   ('/kelas-master/{kelas}',  [KelasMasterController::class, 'update'])->name('kelas-master.update');
    Route::delete('/kelas-master/{kelas}',  [KelasMasterController::class, 'destroy'])->name('kelas-master.destroy');
});

// Admin: mentor-presensi list, reports, export
Route::middleware(['auth', 'role:admin,mentor'])->prefix('admin/mentor-presensi')->name('admin.mentor-presensi.')->group(function () {
    Route::get('/',             [MentorPresensiAdminController::class, 'index'])->name('index');
    Route::get('/reports',      [MentorPresensiAdminController::class, 'reports'])->name('reports');
    Route::get('/export/excel', [MentorPresensiAdminController::class, 'exportExcel'])->name('export.excel');
    Route::get('/export/pdf',   [MentorPresensiAdminController::class, 'exportPdf'])->name('export.pdf');
});

// Certificate Generator (admin only)
Route::middleware(['auth', 'role:admin'])->prefix('admin/certificates')->name('admin.certificates.')->group(function () {
    Route::get   ('templates',                    [CertificateTemplateController::class, 'index'])         ->name('templates.index');
    Route::get   ('templates/create',             [CertificateTemplateController::class, 'create'])        ->name('templates.create');
    Route::post  ('templates',                    [CertificateTemplateController::class, 'store'])         ->name('templates.store');
    Route::post  ('templates/preview',            [CertificateTemplateController::class, 'preview'])       ->name('templates.preview');
    Route::get   ('templates/{template}/preview', [CertificateTemplateController::class, 'previewSaved'])  ->name('templates.preview.saved');
    Route::get   ('templates/{template}/edit',    [CertificateTemplateController::class, 'edit'])          ->name('templates.edit');
    Route::put   ('templates/{template}',         [CertificateTemplateController::class, 'update'])        ->name('templates.update');
    Route::delete('templates/{template}',         [CertificateTemplateController::class, 'destroy'])       ->name('templates.destroy');

    Route::get   ('issued',                    [IssuedCertificateController::class, 'index'])     ->name('issued.index');
    Route::post  ('issued',                    [IssuedCertificateController::class, 'store'])     ->name('issued.store');
    Route::get   ('issued/{cert}/download',    [IssuedCertificateController::class, 'download'])  ->name('issued.download');
    Route::delete('issued/{cert}',             [IssuedCertificateController::class, 'destroy'])   ->name('issued.destroy');
});

// Scholarship Journal (student)
use App\Http\Controllers\Web\ScholarshipJournalController;
Route::middleware(['auth', 'role:student'])->prefix('jurnal-mahasiswa')->name('scholarship-journal.')->group(function () {
    Route::get('/',          [ScholarshipJournalController::class, 'index'])->name('index');
    Route::get('/buat',      [ScholarshipJournalController::class, 'create'])->name('create');
    Route::post('/',         [ScholarshipJournalController::class, 'store'])->name('store');
    Route::get('/{id}',      [ScholarshipJournalController::class, 'show'])->name('show');
    Route::get('/{id}/edit', [ScholarshipJournalController::class, 'edit'])->name('edit');
    Route::put('/{id}',      [ScholarshipJournalController::class, 'update'])->name('update');
});

// College: jurnal harian (daily check-in) + review dashboard
use App\Http\Controllers\Web\College\JournalReviewController;
use App\Http\Controllers\Web\College\CollegeJurnalController;
Route::middleware(['auth', 'role:college,admin'])->prefix('college')->name('college.')->group(function () {
    Route::get('/dashboard',              [JournalReviewController::class, 'dashboard'])->name('dashboard');
    Route::get('/jurnal/{id}',            [JournalReviewController::class, 'show'])->name('journal.show');
    Route::post('/jurnal/{id}/review',    [JournalReviewController::class, 'review'])->name('journal.review');
});

Route::middleware(['auth', 'role:college'])->prefix('jurnal-college')->name('college-jurnal.')->group(function () {
    Route::get('/',              [CollegeJurnalController::class, 'index'])->name('index');
    Route::get('/user/{userId}', [CollegeJurnalController::class, 'showOther'])->name('other');
    Route::post('/toggle',       [CollegeJurnalController::class, 'toggle'])->name('toggle');
    Route::post('/foto',         [CollegeJurnalController::class, 'uploadFoto'])->name('foto.upload');
    Route::delete('/foto',       [CollegeJurnalController::class, 'deleteFoto'])->name('foto.delete');
});

// Admin: Jurnal College (progress, laporan, alkitab, items)
use App\Http\Controllers\Web\Admin\CollegeJurnalAdminController;
use App\Http\Controllers\Web\Admin\CollegeBibleController;
use App\Http\Controllers\Web\Admin\CollegeBibleScheduleController;
use App\Http\Controllers\Web\Admin\CollegeItemController;
Route::middleware(['auth', 'role:admin,mentor'])->prefix('admin/jurnal-college')->name('admin.jurnal-college.')->group(function () {
    Route::get('/',                         [CollegeJurnalAdminController::class, 'dashboard'])->name('index');
    Route::get('/laporan',                       [CollegeJurnalAdminController::class, 'index'])->name('laporan');
    Route::get('/laporan/{user}',                [CollegeJurnalAdminController::class, 'show'])->name('show');
    Route::get('/laporan/{user}/export',         [CollegeJurnalAdminController::class, 'export'])->name('export');
    Route::get('/users/{user}/quick-setup',      [CollegeJurnalAdminController::class, 'quickSetup'])->name('quick-setup');
    Route::post('/users/{user}/quick-setup',     [CollegeJurnalAdminController::class, 'quickUpdate'])->name('quick-update');

    // Jadwal Pembacaan Alkitab — CRUD
    Route::get('/bible-schedules',                    [CollegeBibleScheduleController::class, 'index'])->name('bible-schedules.index');
    Route::get('/bible-schedules/create',             [CollegeBibleScheduleController::class, 'create'])->name('bible-schedules.create');
    Route::post('/bible-schedules',                   [CollegeBibleScheduleController::class, 'store'])->name('bible-schedules.store');
    Route::get('/bible-schedules/{bibleSchedule}/edit', [CollegeBibleScheduleController::class, 'edit'])->name('bible-schedules.edit');
    Route::put('/bible-schedules/{bibleSchedule}',    [CollegeBibleScheduleController::class, 'update'])->name('bible-schedules.update');
    Route::delete('/bible-schedules/{bibleSchedule}', [CollegeBibleScheduleController::class, 'destroy'])->name('bible-schedules.destroy');
    Route::post('/bible-schedules/{bibleSchedule}/set-active', [CollegeBibleScheduleController::class, 'setActive'])->name('bible-schedules.set-active');

    // Detail hari per jadwal
    Route::get('/bible',                    [CollegeBibleController::class, 'index'])->name('bible');
    Route::put('/bible/anchor',             [CollegeBibleController::class, 'updateAnchor'])->name('bible.anchor');
    Route::post('/bible/import',            [CollegeBibleController::class, 'importJson'])->name('bible.import');
    Route::put('/bible/{item}',             [CollegeBibleController::class, 'update'])->name('bible.update');

    Route::get('/items',                    [CollegeItemController::class, 'index'])->name('items.index');
    Route::post('/items',                   [CollegeItemController::class, 'store'])->name('items.store');
    Route::put('/items/{item}',             [CollegeItemController::class, 'update'])->name('items.update');
    Route::delete('/items/{item}',          [CollegeItemController::class, 'destroy'])->name('items.destroy');
});

use App\Http\Controllers\Web\ScholarshipTeenager\ScholarshipTeenagerJurnalController;
use App\Http\Controllers\Web\Admin\ScholarshipTeenagerJurnalAdminController;
use App\Http\Controllers\Web\Admin\ScholarshipTeenagerItemAdminController;

Route::middleware(['auth', 'role:scholarship_teenager'])->prefix('jurnal-scholarship-teenager')->name('scholarship-teenager-jurnal.')->group(function () {
    Route::get('/',              [ScholarshipTeenagerJurnalController::class, 'index'])->name('index');
    Route::get('/user/{userId}', [ScholarshipTeenagerJurnalController::class, 'showOther'])->name('other');
    Route::post('/toggle',       [ScholarshipTeenagerJurnalController::class, 'toggle'])->name('toggle');
    Route::post('/foto',         [ScholarshipTeenagerJurnalController::class, 'uploadFoto'])->name('foto.upload');
    Route::delete('/foto',       [ScholarshipTeenagerJurnalController::class, 'deleteFoto'])->name('foto.delete');
});

Route::middleware(['auth', 'role:admin,mentor'])->prefix('admin/jurnal-scholarship-teenager')->name('admin.jurnal-scholarship-teenager.')->group(function () {
    Route::get('/',                      [ScholarshipTeenagerJurnalAdminController::class, 'dashboard'])->name('index');
    Route::get('/laporan',                       [ScholarshipTeenagerJurnalAdminController::class, 'index'])->name('laporan');
    Route::get('/laporan/{user}',                [ScholarshipTeenagerJurnalAdminController::class, 'show'])->name('show');
    Route::get('/laporan/{user}/export',         [ScholarshipTeenagerJurnalAdminController::class, 'export'])->name('export');
    Route::get('/users/{user}/quick-setup',      [ScholarshipTeenagerJurnalAdminController::class, 'quickSetup'])->name('quick-setup');
    Route::post('/users/{user}/quick-setup',     [ScholarshipTeenagerJurnalAdminController::class, 'quickUpdate'])->name('quick-update');
    Route::get('/items',                 [ScholarshipTeenagerItemAdminController::class, 'index'])->name('items.index');
    Route::post('/items',                [ScholarshipTeenagerItemAdminController::class, 'store'])->name('items.store');
    Route::put('/items/{item}',          [ScholarshipTeenagerItemAdminController::class, 'update'])->name('items.update');
    Route::delete('/items/{item}',       [ScholarshipTeenagerItemAdminController::class, 'destroy'])->name('items.destroy');
});

use App\Http\Controllers\Web\Prajurit\PrajuritJurnalController;
use App\Http\Controllers\Web\Admin\PrajuritJurnalAdminController;

Route::middleware(['auth', 'role:prajurit'])->prefix('jurnal-prajurit')->name('prajurit-jurnal.')->group(function () {
    Route::get('/',        [PrajuritJurnalController::class, 'index'])->name('index');
    Route::post('/toggle', [PrajuritJurnalController::class, 'toggle'])->name('toggle');
    Route::post('/foto',   [PrajuritJurnalController::class, 'uploadFoto'])->name('foto.upload');
});

Route::middleware(['auth', 'role:admin,mentor'])->prefix('admin/jurnal-prajurit')->name('admin.jurnal-prajurit.')->group(function () {
    Route::get('/',                    [PrajuritJurnalAdminController::class, 'dashboard'])->name('index');
    Route::get('/laporan',             [PrajuritJurnalAdminController::class, 'index'])->name('laporan');
    Route::get('/laporan/{user}',      [PrajuritJurnalAdminController::class, 'show'])->name('show');
    Route::get('/laporan/{user}/export', [PrajuritJurnalAdminController::class, 'export'])->name('export');
    Route::get('/summary/{user}',      [PrajuritJurnalAdminController::class, 'summary'])->name('summary');
    Route::post('/scan',               [PrajuritJurnalAdminController::class, 'scanJurnal'])->name('scan');
    Route::post('/save',               [PrajuritJurnalAdminController::class, 'saveJurnal'])->name('save');
    Route::post('/reset',              [PrajuritJurnalAdminController::class, 'resetJurnal'])->name('reset');
    Route::post('/qr-massal',          [PrajuritJurnalAdminController::class, 'bulkQrPrint'])->name('bulk-qr');
});

Route::middleware(['auth', 'role:admin,mentor'])->prefix('admin/jurnal-hub')->name('admin.jurnal-hub.')->group(function () {
    Route::get('/',             [AdminJurnalHubController::class, 'index'])->name('index');
    Route::get('/users',        [AdminJurnalHubController::class, 'users'])->name('users');
    Route::get('/matrix/{user}',[AdminJurnalHubController::class, 'matrix'])->name('matrix');
    Route::get('/export/{user}',[AdminJurnalHubController::class, 'exportCsv'])->name('export');
    Route::get('/stats',        [AdminJurnalHubController::class, 'stats'])->name('stats');
    Route::post('/config',      [AdminJurnalHubController::class, 'updateConfig'])->name('config');
});

Route::view('/privacy-policy', 'privacy');

// ── Penghapusan Data Akun (Google Play Data Safety) ─────────────────────
use App\Http\Controllers\Web\DataDeletionController;
Route::get('/hapus-akun', [DataDeletionController::class, 'show'])->name('data-deletion.show');
Route::delete('/hapus-akun', [DataDeletionController::class, 'destroy'])->middleware('auth')->name('data-deletion.destroy');


// ── Android APK download (non-Play-Store distribution) ──────────────────
Route::get('/download-android', function () {
    $files = glob(public_path('downloads/sc_student_v*.apk'));
    usort($files, function($a, $b) {
        preg_match('/v([\d\.]+)_(\d+)/', basename($a), $matchA);
        preg_match('/v([\d\.]+)_(\d+)/', basename($b), $matchB);
        $cmp = version_compare($matchA[1] ?? '0.0.0', $matchB[1] ?? '0.0.0');
        if ($cmp === 0) {
            return ($matchA[2] ?? 0) <=> ($matchB[2] ?? 0);
        }
        return $cmp;
    });
    $latestFile = end($files);
    
    $version = 'Unknown';
    $size = 0;
    $date = '';
    $filename = '';
    $releaseNotes = '';
    
    if ($latestFile) {
        preg_match('/v([\d\.]+)_(\d+)/', basename($latestFile), $matches);
        $version = ($matches[1] ?? 'Unknown') . ' (Build ' . ($matches[2] ?? '?') . ')';
        $size = round(filesize($latestFile) / 1024 / 1024, 1);
        $date = \Carbon\Carbon::createFromTimestamp(filemtime($latestFile))->locale('id')->translatedFormat('d F Y');
        $filename = basename($latestFile);
        
        $notesFile = str_replace('.apk', '_release_notes.txt', $latestFile);
        if (file_exists($notesFile)) {
            $releaseNotes = \Illuminate\Support\Str::markdown(file_get_contents($notesFile));
        }
    }

    return view('download-android', compact('version', 'size', 'date', 'filename', 'releaseNotes'));
})->name('download.android');

Route::get('/download/apk', function () {
    $files = glob(public_path('downloads/sc_student_v*.apk'));
    usort($files, function($a, $b) {
        preg_match('/v([\d\.]+)_(\d+)/', basename($a), $matchA);
        preg_match('/v([\d\.]+)_(\d+)/', basename($b), $matchB);
        $cmp = version_compare($matchA[1] ?? '0.0.0', $matchB[1] ?? '0.0.0');
        if ($cmp === 0) {
            return ($matchA[2] ?? 0) <=> ($matchB[2] ?? 0);
        }
        return $cmp;
    });
    $latestFile = end($files);
    
    abort_unless($latestFile && file_exists($latestFile), 404);
    return response()->download($latestFile, basename($latestFile));
})->name('download.apk');

Route::post('/beta-tester/register', function(\Illuminate\Http\Request $request) {
    $request->validate([
        'email' => 'required|email|max:100',
        'whatsapp' => ['required', 'string', 'max:20', 'regex:/^[0-9\+\-\s]+$/']
    ], [
        'whatsapp.regex' => 'Format nomor WhatsApp tidak valid. Hanya angka dan karakter + yang diizinkan.'
    ]);
    
    // Save to DB using Eloquent (protected against SQL Injection)
    \App\Models\BetaTester::create([
        'email' => $request->email,
        'whatsapp' => $request->whatsapp,
        'status' => 'pending'
    ]);
    
    return back()->with('success', 'Berhasil! Permintaan akses Anda telah diterima. Tim kami akan segera mengirimkan link Play Store ke nomor WhatsApp Anda ('.htmlspecialchars($request->whatsapp).') setelah disetujui.');
})->name('beta.register')->middleware('throttle:5,1');

// ── Chat ─────────────────────────────────────────────────────────────────
use App\Http\Controllers\Chat\ChatController;
use App\Http\Controllers\Chat\ConversationController;
use App\Http\Controllers\Chat\MessageController;

Route::middleware(['auth'])->prefix('chat')->name('chat.')->group(function () {
    Route::get('/', [ChatController::class, 'index'])->name('index');

    // Conversations
    Route::get('/conversations/{conversation}/messages',  [ConversationController::class, 'messages'])->name('messages');
    Route::post('/private/{userId}',                      [ConversationController::class, 'startPrivate'])->name('private');
    Route::post('/group',                                 [ConversationController::class, 'createGroup'])->name('group.create');

    // Messages
    Route::post('/conversations/{conversation}/messages', [MessageController::class, 'send'])->name('send');
    Route::delete('/messages/{message}',                  [MessageController::class, 'destroy'])->name('message.destroy');
    Route::post('/conversations/{conversation}/read',     [MessageController::class, 'markRead'])->name('read');
});

// Chat unread count (untuk floating button badge)
Route::middleware(['auth'])->get('/chat/unread-count', function () {
    $userId = Auth::id();
    $count  = \App\Models\Conversation::whereHas(
        'participants', fn($q) => $q->where('user_id', $userId)
    )->get()->sum(fn($c) => $c->unreadCount($userId));
    return response()->json(['count' => $count]);
})->name('chat.unread-count');
// ── Admin Collected Emails ──────────────────────────────────────────────
Route::middleware(['auth', 'role:admin'])->prefix('admin/collected-emails')->name('admin.collected-emails.')->group(function () {
    Route::get('/',                                   [\App\Http\Controllers\CollectedEmailController::class, 'index'])->name('index');
    Route::post('/{collectedEmail}/toggle-invite',    [\App\Http\Controllers\CollectedEmailController::class, 'toggleInvite'])->name('toggle-invite');
});

<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Blog;
use App\Models\Cabang;

class HomeController extends Controller
{
    public function index()
    {
        if (auth()->check()) {
            $user = auth()->user();
            if ($user->isAdmin()) {
                return redirect()->route('admin.dashboard');
            }
            
            // Only redirect to beranda if they have access to it, otherwise they will get caught in a redirect loop
            if ($user->hasRole(['student', 'college', 'scholarship_teenager', 'mentor'])) {
                return redirect()->route('beranda');
            }
            
            // If they are just a guest or have no roles, let them see the home page
            // We shouldn't redirect them because they don't have access to /beranda
        }

        $blogs = Blog::with(['user', 'cabang', 'tags'])
            ->whereNotNull('published_at')
            ->latest('published_at')
            ->take(6)
            ->get();

        $cabangs = Cabang::all();

        return view('home', compact('blogs', 'cabangs'));
    }
}

import 'package:flutter/material.dart';

/// Placeholder — real user management CRUD (Fase 2) lands here.
/// Backend: /api/admin/users (role:admin).
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Manajemen Pengguna — segera hadir',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

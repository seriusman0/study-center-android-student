import 'package:flutter/material.dart';

/// Placeholder — real admin dashboard stats (Fase 2) lands here.
/// Backend: GET /api/admin/dashboard (role:admin).
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Dashboard Admin — segera hadir',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaintenanceNotifier extends StateNotifier<bool> {
  MaintenanceNotifier() : super(false);
  void setMaintenance(bool value) => state = value;
}

final maintenanceProvider = StateNotifierProvider<MaintenanceNotifier, bool>((ref) {
  return MaintenanceNotifier();
});

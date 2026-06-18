import 'package:flutter/material.dart';

class DrawerProvider with ChangeNotifier {
  // Mặc định Sidebar sẽ mở rộng
  bool _isDesktopCollapsed = false;

  bool get isDesktopCollapsed => _isDesktopCollapsed;

  void toggleDesktopCollapse() {
    _isDesktopCollapsed = !_isDesktopCollapsed;
    notifyListeners();
  }
}

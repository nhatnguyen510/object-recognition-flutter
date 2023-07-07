import 'package:flutter/material.dart';

class NavigationController extends ChangeNotifier {
  String sreenName = "/";

  void changeScreen(String newScreen) {
    sreenName = newScreen;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';

class RouterNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

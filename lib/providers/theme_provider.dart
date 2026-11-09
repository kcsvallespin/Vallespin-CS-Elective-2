import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Light/dark toggle, like the PrelimExam shop.
final darkModeProvider = NotifierProvider<DarkModeController, bool>(
  DarkModeController.new,
);

class DarkModeController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

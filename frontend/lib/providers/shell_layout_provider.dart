import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellLayoutState {
  final String title;
  final List<Widget> actions;

  ShellLayoutState({
    this.title = '',
    this.actions = const [],
  });

  ShellLayoutState copyWith({
    String? title,
    List<Widget>? actions,
  }) {
    return ShellLayoutState(
      title: title ?? this.title,
      actions: actions ?? this.actions,
    );
  }
}

class ShellLayoutNotifier extends StateNotifier<ShellLayoutState> {
  ShellLayoutNotifier() : super(ShellLayoutState());

  void update({
    required String title,
    List<Widget> actions = const [],
  }) {
    Future.microtask(() {
      state = ShellLayoutState(title: title, actions: actions);
    });
  }
}

final shellLayoutProvider = StateNotifierProvider<ShellLayoutNotifier, ShellLayoutState>((ref) {
  return ShellLayoutNotifier();
});

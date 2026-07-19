import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellLayoutState {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<String> breadcrumbs;

  ShellLayoutState({
    this.title = '',
    this.subtitle,
    this.actions = const [],
    this.breadcrumbs = const [],
  });

  ShellLayoutState copyWith({
    String? title,
    String? subtitle,
    List<Widget>? actions,
    List<String>? breadcrumbs,
  }) {
    return ShellLayoutState(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      actions: actions ?? this.actions,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
    );
  }
}

class ShellLayoutNotifier extends StateNotifier<ShellLayoutState> {
  ShellLayoutNotifier() : super(ShellLayoutState());

  void update({
    required String title,
    String? subtitle,
    List<Widget> actions = const [],
    List<String> breadcrumbs = const [],
  }) {
    Future.microtask(() {
      state = ShellLayoutState(
        title: title,
        subtitle: subtitle,
        actions: actions,
        breadcrumbs: breadcrumbs,
      );
    });
  }
}

final shellLayoutProvider =
    StateNotifierProvider<ShellLayoutNotifier, ShellLayoutState>((ref) {
      return ShellLayoutNotifier();
    });

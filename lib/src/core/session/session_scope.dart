import 'package:flutter/widgets.dart';

import 'auth_session_controller.dart';

class SessionScope extends InheritedNotifier<AuthSessionController> {
  const SessionScope({
    required AuthSessionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AuthSessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope is missing from the widget tree.');
    return scope!.notifier!;
  }

  static AuthSessionController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    return scope?.notifier;
  }
}

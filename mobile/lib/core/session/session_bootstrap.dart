// FILE: lib/core/session/session_bootstrap.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../push/push_service.dart';
import '../realtime/realtime_service.dart';

/// Starts the realtime socket and push notifications once the user is signed
/// in and inside the main tabs. Watched by the tab scaffold.
final sessionBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(realtimeServiceProvider).start();
  // Push may prompt for permission; never block the UI on it.
  ref.read(pushServiceProvider).start();
});

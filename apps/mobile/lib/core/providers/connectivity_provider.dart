import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demo connectivity flag until connectivity_plus drives sync UI.
final isOfflineProvider = StateProvider<bool>((ref) => false);

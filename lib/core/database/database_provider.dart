import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Must be overridden in main() with the opened database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden');
});

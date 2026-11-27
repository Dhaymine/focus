import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_settings.dart';
import 'generated/app_localizations.dart';

/// Localizations for the language currently chosen in the app (no BuildContext).
AppLocalizations currentL10n(Ref ref) {
  final locale =
      ref.read(localeProvider) ?? PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.delegate.isSupported(locale);
  return lookupAppLocalizations(supported ? locale : const Locale('en'));
}

// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

Future<void> ensureGoogleMapsLoadedImpl({required String apiKey}) async {
  // If already loaded, do nothing.
  if (js_util.hasProperty(html.window, 'google')) {
    final existing = js_util.getProperty(html.window, 'google');
    if (existing != null) return;
  }

  if (apiKey.trim().isEmpty) {
    throw StateError('Missing MAPS_API_KEY for web');
  }

  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..async = true
    ..defer = true
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey';

  final completer = Completer<void>();
  script.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Failed to load Google Maps JS API'));
    }
  });
  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });

  html.document.head?.append(script);

  await completer.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => throw TimeoutException('Timed out loading Google Maps JS API'),
  );
}

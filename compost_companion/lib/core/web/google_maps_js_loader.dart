import 'google_maps_js_loader_stub.dart'
    if (dart.library.html) 'google_maps_js_loader_web.dart';

/// Ensures the Google Maps JavaScript SDK is loaded on web.
///
/// On non-web platforms this is a no-op.
Future<void> ensureGoogleMapsLoaded({required String apiKey}) =>
    ensureGoogleMapsLoadedImpl(apiKey: apiKey);

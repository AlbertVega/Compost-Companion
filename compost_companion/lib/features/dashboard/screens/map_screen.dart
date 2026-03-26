import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:compost_companion/core/web/google_maps_js_loader.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Mock battery locations (pilas)
  final List<LatLng> _batteryLocations = const [
    LatLng(9.9281, -84.0907),
    LatLng(9.935, -84.08),
  ];

  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(9.9281, -84.0907),
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _rebuildBatteryMarkers();
  }

  void _rebuildBatteryMarkers() {
    final markers = <Marker>{};
    for (int i = 0; i < _batteryLocations.length; i++) {
      final pos = _batteryLocations[i];
      markers.add(
        Marker(
          markerId: MarkerId('battery_$i'),
          position: pos,
          infoWindow: InfoWindow(title: 'Pila #${i + 1}'),
          onTap: () {
            // Keep it simple for now
          },
        ),
      );
    }

    if (_selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: _selectedLocation!,
          icon: kIsWeb
              ? BitmapDescriptor.defaultMarker
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Selected location'),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _rebuildBatteryMarkers();
  }

  Future<void> _createBatteryHere() async {
    final pos = _selectedLocation;
    if (pos == null) return;

    setState(() {
      _selectedLocation = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created pila at (${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})')),
    );
    _rebuildBatteryMarkers();
  }

  bool get _mapSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    const mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          Positioned.fill(
            child: _mapSupported
                ? (kIsWeb
                    ? FutureBuilder<void>(
                        future: ensureGoogleMapsLoaded(apiKey: mapsApiKey),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Google Maps failed to load on web.',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Run with: flutter run -d chrome --dart-define=MAPS_API_KEY=YOUR_KEY',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      snapshot.error.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return GoogleMap(
                            initialCameraPosition: _initialCamera,
                            markers: _markers,
                            onTap: _onMapTap,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                          );
                        },
                      )
                    : GoogleMap(
                        initialCameraPosition: _initialCamera,
                        markers: _markers,
                        onTap: _onMapTap,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ))
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'Map preview is available on Android/iOS/Web.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text('Mock pilas: ${_batteryLocations.length}'),
                        ],
                      ),
                    ),
                  ),
          ),
          if (_selectedLocation != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PointerInterceptor(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Create Battery Here?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '(${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)})',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _createBatteryHere,
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
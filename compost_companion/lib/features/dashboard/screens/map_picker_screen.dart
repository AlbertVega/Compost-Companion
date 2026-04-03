import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _fallbackCenter = LatLng(53.5461, -113.4938);
  static const String _googleGeocodingApiKey = 'AIzaSyDyGNSWSr3q8yQhMwu0JLgTmYBqtywZyLE';

  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng? selectedLocation;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAndNavigate() async {
    final String query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isSearching = true;
    });

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'address': query,
          'key': _googleGeocodingApiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        _showError('Search failed. Server error ${response.statusCode}.');
        return;
      }

      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' &&
          data['results'] != null &&
          (data['results'] as List).isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];

        final LatLng target = LatLng(
          (location['lat'] as num).toDouble(),
          (location['lng'] as num).toDouble(),
        );

        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 15.0),
          ),
        );
      } else if (data['status'] == 'ZERO_RESULTS') {
        _showError('Location not found.');
      } else {
        _showError('Search failed: ${data['status']}');
      }
    } catch (e) {
      _showError('Search failed. Check internet and API setup.');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {
      if (selectedLocation != null)
        Marker(
          markerId: const MarkerId('selected_location'),
          position: selectedLocation!,
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: selectedLocation ?? _fallbackCenter,
                zoom: 14,
              ),
              markers: markers,
              onTap: (position) {
                setState(() {
                  selectedLocation = position;
                });
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF2F6F4E)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchAndNavigate(),
                            decoration: const InputDecoration(
                              hintText: 'Search a place or address',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_isSearching)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            onPressed: _searchAndNavigate,
                            icon: const Icon(Icons.arrow_forward, color: Color(0xFF2F6F4E)),
                            tooltip: 'Search',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'Tap the map to choose a compost pile location',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          selectedLocation == null
                              ? 'No location selected'
                              : '${_formatCoordinate(selectedLocation!.latitude)}, ${_formatCoordinate(selectedLocation!.longitude)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: selectedLocation == null
                              ? null
                              : () => Navigator.pop(context, selectedLocation),
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F6F4E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCoordinate(double value) {
  return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
}

LatLng parseLocation(String location) {
  final parts = location.split(',');
  if (parts.length != 2) {
    throw FormatException('Invalid location format');
  }

  return LatLng(
    double.parse(parts[0].trim()),
    double.parse(parts[1].trim()),
  );
}
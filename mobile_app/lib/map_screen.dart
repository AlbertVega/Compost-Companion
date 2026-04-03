import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Model for Pin Data
class SoilPin {
  final String id;
  final String name;
  final LatLng position;
  final double moisture;
  final String health;
  final DateTime lastUpdated;

  SoilPin({
    required this.id,
    required this.name,
    required this.position,
    this.moisture = 65.0,
    this.health = 'Good',
    required this.lastUpdated,
  });
}

class MapScreen extends StatefulWidget {
  final Map<String, SoilPin> globalPins;
  final Function(SoilPin) onAddPin;
  final Function(String) onRemovePin;

  const MapScreen({
    super.key,
    required this.globalPins,
    required this.onAddPin,
    required this.onRemovePin,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  LatLng _center = const LatLng(53.5461, -113.4938);
  LatLng? _tempPinPosition;

  bool _isDropMode = false;
  bool _locationPermissionGranted = false;
  bool _isSearching = false;
  bool _isMapReady = false;

  static const String _googleGeocodingApiKey =
      'AIzaSyDyGNSWSr3q8yQhMwu0JLgTmYBqtywZyLE';

  static const double _topMapPadding = 96;
  static const double _rightMapPadding = 72;
  static const double _bottomMapPadding = 140;
  static const double _leftMapPadding = 16;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError(
        'Location permission permanently denied. Enable it in app settings.',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _locationPermissionGranted = true;
    });

    await _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final LatLng currentLatLng = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _center = currentLatLng;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLatLng,
            zoom: 17.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      _showError('Unable to get your current location.');
    }
  }

  Future<void> _searchAndNavigate() async {
    final String query = _searchController.text.trim();
    if (query.isEmpty) return;

    for (final pin in widget.globalPins.values) {
      if (pin.name.toLowerCase() == query.toLowerCase()) {
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: pin.position, zoom: 17.0),
          ),
        );
        return;
      }
    }

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
      debugPrint('Search error: $e');
      _showError('Search failed. Check internet and API setup.');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _startDropMode() async {
    if (_mapController == null || !_isMapReady) {
      _showError('Map is still loading.');
      return;
    }

    try {
      final LatLngBounds bounds = await _mapController!.getVisibleRegion();

      final double centerLat =
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
      final double centerLng =
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

      if (!mounted) return;
      setState(() {
        _isDropMode = true;
        _tempPinPosition = LatLng(centerLat, centerLng);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Drag the red pin anywhere you want, then tap the check button.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error starting drop mode: $e');
      if (!mounted) return;
      setState(() {
        _isDropMode = true;
        _tempPinPosition = _center;
      });
    }
  }

  void _toggleDropMode() {
    if (_isDropMode) {
      if (_tempPinPosition == null) {
        _showError('No pin selected.');
        return;
      }
      _showLabelDialog(_tempPinPosition!);
    } else {
      _startDropMode();
    }
  }

  void _cancelDropMode() {
    setState(() {
      _isDropMode = false;
      _tempPinPosition = null;
    });
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

  void _showLabelDialog(LatLng position) {
    final TextEditingController labelController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Label this Pin'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(
            hintText: 'e.g. Pile A, My Garden',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _isDropMode = false;
                _tempPinPosition = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final String name = labelController.text.trim().isEmpty
                  ? 'New Pin'
                  : labelController.text.trim();

              widget.onAddPin(
                SoilPin(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  position: position,
                  lastUpdated: DateTime.now(),
                ),
              );

              if (!mounted) return;
              setState(() {
                _isDropMode = false;
                _tempPinPosition = null;
              });

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPinDetails(String id) {
    final pin = widget.globalPins[id];
    if (pin == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pin.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    widget.onRemovePin(id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.health_and_safety,
              'Soil Health',
              pin.health,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.water_drop,
              'Moisture',
              '${pin.moisture}%',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.location_on,
              'Coordinates',
              '${pin.position.latitude.toStringAsFixed(4)}, ${pin.position.longitude.toStringAsFixed(4)}',
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = widget.globalPins.values.map((pin) {
      return Marker(
        markerId: MarkerId(pin.id),
        position: pin.position,
        onTap: () => _showPinDetails(pin.id),
      );
    }).toSet();

    if (_isDropMode && _tempPinPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('temp_drop_pin'),
          position: _tempPinPosition!,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(title: 'Drag pin to desired spot'),
          zIndex: 2,
          onDragEnd: (LatLng newPosition) {
            if (!mounted) return;
            setState(() {
              _tempPinPosition = newPosition;
            });
          },
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _isMapReady = true;
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              padding: const EdgeInsets.fromLTRB(
                _leftMapPadding,
                _topMapPadding,
                _rightMapPadding,
                _bottomMapPadding,
              ),
              markers: markers,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              onCameraMove: (CameraPosition position) {
                _center = position.target;
              },
              onTap: (LatLng position) {
                if (_isDropMode) {
                  setState(() {
                    _tempPinPosition = position;
                  });
                }
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildCircleButton(
                      Icons.arrow_back_ios_new,
                      () => Navigator.pop(context),
                      size: 44,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _searchAndNavigate(),
                          decoration: InputDecoration(
                            hintText: 'Search location or pin...',
                            border: InputBorder.none,
                            icon: _isSearching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.search,
                                    color: Color(0xFF2F6F4E),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            right: 12,
            child: Column(
              children: [
                if (_isDropMode) ...[
                  _buildMapButton(
                    Icons.close,
                    _cancelDropMode,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildMapButton(
                  _isDropMode ? Icons.check : Icons.add_location_alt,
                  _toggleDropMode,
                  color: _isDropMode ? Colors.green : const Color(0xFF2F6F4E),
                ),
                const SizedBox(height: 12),
                _buildMapButton(
                  Icons.my_location,
                  _determinePosition,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
    IconData icon,
    VoidCallback onTap, {
    double size = 40,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMapButton(
    IconData icon,
    VoidCallback onTap, {
    Color color = const Color(0xFF2F6F4E),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}
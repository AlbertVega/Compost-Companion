import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'notification_screen.dart';

// Model for Pin Data to support future real-time integration
class SoilPin {
  final String id;
  final String name;
  final LatLng position;
  final double moisture; // Dynamic value
  final String health;   // Dynamic value
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
  AppleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  LatLng _center = const LatLng(53.5461, -113.4938); // Default to Edmonton
  bool _isDropMode = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
    });
    
    if (mounted && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: 15.0),
        ),
      );
    }
  }

  Future<void> _searchAndNavigate() async {
    String query = _searchController.text;
    if (query.isEmpty) return;

    // Check if searching for a labeled pin first
    for (var pin in widget.globalPins.values) {
      if (pin.name.toLowerCase() == query.toLowerCase()) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: pin.position, zoom: 15.0),
          ),
        );
        return;
      }
    }

    try {
      List<geo.Location> locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        geo.Location first = locations.first;
        LatLng target = LatLng(first.latitude, first.longitude);
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 14.0),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found. Please try a more specific address.')),
      );
    }
  }

  void _showLabelDialog(LatLng position) {
    final TextEditingController labelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Label this Pin'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(hintText: 'e.g. Pile A, My Garden'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String name = labelController.text.isEmpty ? 'New Pin' : labelController.text;
              final String id = position.toString();
              final newPin = SoilPin(
                id: id,
                name: name,
                position: position,
                lastUpdated: DateTime.now(),
              );
              widget.onAddPin(newPin);
              Navigator.pop(context);
              setState(() {
                _isDropMode = false;
              });
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
                Text(pin.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(id),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.health_and_safety, 'Soil Health', pin.health, color: Colors.green),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.water_drop, 'Moisture', '${pin.moisture}%', color: Colors.blue),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, 'Coordinates', 
              '${pin.position.latitude.toStringAsFixed(4)}, ${pin.position.longitude.toStringAsFixed(4)}',
              color: Colors.grey),
            const Spacer(),
            Center(
              child: Text(
                'Last updated: ${pin.lastUpdated.hour}:${pin.lastUpdated.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pin?'),
        content: const Text('Are you sure you want to remove this pin from the map?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              widget.onRemovePin(id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            },
            child: const Text('Yes, Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(AppleMapController controller) {
    _mapController = controller;
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    final Set<Annotation> annotations = widget.globalPins.values.map((pin) {
      return Annotation(
        annotationId: AnnotationId(pin.id),
        position: pin.position,
        infoWindow: InfoWindow(
          title: pin.name,
          snippet: 'Tap to view soil details',
        ),
        onTap: () {
          _showPinDetails(pin.id);
        },
      );
    }).toSet();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AppleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              annotations: annotations,
              onTap: (LatLng pos) {
                if (_isDropMode) {
                  _showLabelDialog(pos);
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.standard,
            ),
          ),

          // Header Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationScreen()),
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/I104-215;7758-11224.svg',
                              width: 12,
                              height: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Search Bar
                        Expanded(
                          child: Container(
                            height: 44, // Leveled with the back button
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Color(0xFF2F6F4E)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onSubmitted: (_) => _searchAndNavigate(),
                                    decoration: const InputDecoration(
                                      hintText: 'Search for location or pin...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: Color(0xFF4C4C4C),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Map Controls
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                _buildMapButton(
                  _isDropMode ? Icons.close : Icons.add_location_alt,
                  () {
                    setState(() {
                      _isDropMode = !_isDropMode;
                    });
                    if (_isDropMode) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Drop Mode: Tap anywhere on the map to place a pin.')),
                      );
                    }
                  },
                  color: _isDropMode ? Colors.red : const Color(0xFF2F6F4E),
                ),
                const SizedBox(height: 10),
                _buildMapButton(Icons.add, _zoomIn),
                const SizedBox(height: 10),
                _buildMapButton(Icons.remove, _zoomOut),
                const SizedBox(height: 10),
                _buildMapButton(Icons.my_location, _determinePosition),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onPressed, {Color color = const Color(0xFF2F6F4E)}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

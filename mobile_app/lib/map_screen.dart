import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'pile_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();

  final LatLng _center = const LatLng(9.9281, -84.0907); // San Jose, Costa Rica (from design)

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Live Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('pileA'),
                position: _center,
                infoWindow: const InfoWindow(title: 'Backyard Pile A', snippet: 'Active'),
              ),
            },
          ),

          // Header with Search and Logo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 61,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Color(0xFF4C4C4C), fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset('assets/102-211.webp', width: 70, height: 70),
                ],
              ),
            ),
          ),

          // Back Button (Chevron)
          Positioned(
            left: 0,
            top: 403,
            child: GestureDetector(
              onTap: () {
                // Logic to go back or show previous view
              },
              child: SvgPicture.asset('assets/I104-215;7758-11224.svg', width: 10, height: 20),
            ),
          ),

          // Bottom Info Card
          Positioned(
            left: 5,
            bottom: 10,
            child: Container(
              width: 399,
              height: 139,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
              ),
              child: Stack(
                children: [
                  const Positioned(left: 58, top: 15, child: Text('Backyard Pile A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  Positioned(
                    left: 58,
                    top: 37,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF2F6F4E), borderRadius: BorderRadius.circular(16)),
                      child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Positioned(left: 58, top: 64, child: Text('123 Main St, Your City', style: TextStyle(color: Color(0xFF757575), fontSize: 10, fontWeight: FontWeight.bold))),
                  
                  // Buttons
                  Positioned(
                    left: 49,
                    top: 93,
                    child: Container(
                      width: 113,
                      height: 29,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: const Text('Navigate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    left: 214,
                    top: 93,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PileDetailsScreen()),
                        );
                      },
                      child: Container(
                        width: 111,
                        height: 29,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F6F4E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: const Text('View details', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
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

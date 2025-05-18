import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'location_details.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<Marker> _markers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat(reverse: true);
    getCurrentLocation();
    super.initState();
  }

  Future<void> moveToLocation(double lat, double lon) async {
    final newLocation = LatLng(lat, lon);
    _mapController.move(newLocation, 15.0);
    
    setState(() {
      _markers = [
        Marker(
          point: newLocation,
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -10 * _animation.value),
                child: child,
              );
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        ),
      ];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          final requestPermission = await Geolocator.requestPermission();
          if (requestPermission == LocationPermission.denied || requestPermission == LocationPermission.deniedForever) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Izin lokasi diperlukan untuk fitur ini')),
              );
            }
            return;
          }
        }

        if (!await Geolocator.isLocationServiceEnabled()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mohon aktifkan layanan lokasi di perangkat Anda')),
            );
          }
          return;
        }

        final locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: const Duration(seconds: 5),
        );

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
          forceAndroidLocationManager: true,
          locationSettings: locationSettings,
        );
        
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });

          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 15);
          }
          return; // Sukses mendapatkan lokasi
        }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mencoba mendapatkan lokasi kembali... (${retryCount + 1}/$maxRetries)')),
        );
      }
      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 2)); // Tunggu sebentar sebelum mencoba lagi
        continue;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mendapatkan lokasi setelah $maxRetries percobaan: ${e.toString()}')),
          );
        }
        break;
      }
    }
    }
  }

  Future<void> searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng searchResult = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _markers = [
            Marker(
              point: searchResult,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  showMaterialModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => LocationDetails(
                      name: query,
                      rating: 4.5, // Example rating
                      openStatus: 'Open', // Example status
                      imageUrl: 'https://example.com/image.jpg', // Example image URL
                    ),
                  );
                },
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ),
          ];
        });

        _mapController.move(searchResult, 15);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching location: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? const LatLng(0, 0),
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.flutter_map_app',
          tileProvider: NetworkTileProvider(),
          maxZoom: 18,
          minZoom: 3,
          keepBuffer: 8,
          tileSize: 256,
          maxNativeZoom: 18,
          evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
        ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 50,
                height: 50,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.3 * _animation.value),
                      ),
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search location...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    _markers.clear();
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                searchLocation(value);
              }
            },
          ),
        ),
      ),
    ]);
  }
}
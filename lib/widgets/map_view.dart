import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
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
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  List<LatLng> _routePoints = [];
  final String _openRouteServiceApiKey = '5b3ce3597851110001cf6248ead1d3cd429d42d8b6e3551364afa4ee';
  double? _routeDistance;
  double? _routeDuration;

  // Helper method to calculate appropriate zoom level based on coordinate span
  double _calculateZoomLevel(double span) {
    // Base calculation on the relationship between zoom levels and coordinate spans
    // Zoom level 0 shows the entire world (360 degrees)
    // Each zoom level divides the span by 2
    const double worldSpan = 360.0;
    const double maxZoom = 18.0; // Maximum zoom level
    const double minZoom = 3.0;  // Minimum zoom level
    
    // Calculate ideal zoom level
    double zoom = (log(worldSpan / span) / log(2.0));
    
    // Add padding to ensure the route is visible with some margin
    zoom = zoom - 0.5;
    
    // Clamp zoom level between min and max values
    return zoom.clamp(minZoom, maxZoom);
  }

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

  Future<void> _getDirections(LatLng start, LatLng end) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car')
          .replace(queryParameters: {
            'api_key': _openRouteServiceApiKey,
            'start': '${start.longitude},${start.latitude}',
            'end': '${end.longitude},${end.latitude}',
          }),
        headers: {
          'Accept': 'application/json, application/geo+json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final geometry = feature['geometry'];
          final properties = feature['properties'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = (geometry['coordinates'] as List)
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

            // Extract distance and duration from properties
            final summary = properties['summary'];
            double distanceVal = summary['distance'] as double;
            double durationVal = summary['duration'] as double;

            setState(() {
              _routePoints = coordinates.cast<LatLng>();
              _routeDistance = distanceVal / 1000;
              _routeDuration = durationVal / 60;
              // Add markers for start and end points
              _markers = [
                Marker(
                  point: start,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                ),
                Marker(
                  point: end,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ];
            });

            // Fit the map bounds to show the entire route
            // Calculate the bounds and center the map to show the entire route
            if (_routePoints.isNotEmpty) {
              double minLat = _routePoints.first.latitude;
              double maxLat = _routePoints.first.latitude;
              double minLng = _routePoints.first.longitude;
              double maxLng = _routePoints.first.longitude;

              for (var point in _routePoints) {
                minLat = point.latitude < minLat ? point.latitude : minLat;
                maxLat = point.latitude > maxLat ? point.latitude : maxLat;
                minLng = point.longitude < minLng ? point.longitude : minLng;
                maxLng = point.longitude > maxLng ? point.longitude : maxLng;
              }

              final centerLat = (minLat + maxLat) / 2;
              final centerLng = (minLng + maxLng) / 2;
              final center = LatLng(centerLat, centerLng);
              
              // Calculate appropriate zoom level
              final latZoom = _calculateZoomLevel(maxLat - minLat);
              final lngZoom = _calculateZoomLevel(maxLng - minLng);
              final zoom = latZoom < lngZoom ? latZoom : lngZoom;

              _mapController.move(center, zoom);
            }

            // Show route details if properties are available
            if (mounted && properties != null && properties['summary'] != null) {
              final summary = properties['summary'];
              double distance = summary['distance'] as double;
              double duration = summary['duration'] as double;

              double distanceInKm = distance / 1000;
              double durationInMinutes = duration / 60;

              showMaterialModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => RouteDetails(
                  distance: distanceInKm,
                  duration: durationInMinutes,
                ),
              );
            }
          }
        }
      } else {
        throw Exception('Failed to get route directions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> moveToLocation(double lat, double lon) async {
    final newLocation = LatLng(lat, lon);
    
    // Always add the new location marker
    setState(() {
      _markers.add(
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
      );
    });
    
    // Get directions if we have current location
    if (_currentLocation != null) {
      await _getDirections(_currentLocation!, newLocation);
    }
    
    // Calculate bounds to include all markers and routes
    if (_routePoints.isNotEmpty || _markers.isNotEmpty) {
      double minLat = lat;
      double maxLat = lat;
      double minLng = lon;
      double maxLng = lon;

      // Include all route points in bounds
      for (var point in _routePoints) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }
      
      // Include all markers in bounds
      for (var marker in _markers) {
        minLat = min(minLat, marker.point.latitude);
        maxLat = max(maxLat, marker.point.latitude);
        minLng = min(minLng, marker.point.longitude);
        maxLng = max(maxLng, marker.point.longitude);
      }

      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final center = LatLng(centerLat, centerLng);
      
      // Calculate appropriate zoom level
      final latZoom = _calculateZoomLevel(maxLat - minLat);
      final lngZoom = _calculateZoomLevel(maxLng - minLng);
      final zoom = min(latZoom, lngZoom);

      _mapController.move(center, zoom);
    } else {
      _mapController.move(newLocation, 15.0);
    }
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

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search')
          .replace(queryParameters: {
            'q': query,
            'format': 'json',
            'addressdetails': '1',
            'limit': '5',
          }),
        headers: {'User-Agent': 'Flutter_Map_App'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchSuggestions = data.map((place) => {
            'display_name': place['display_name'] as String,
            'lat': double.parse(place['lat']),
            'lon': double.parse(place['lon']),
            'address': place['address'] as Map<String, dynamic>,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching suggestions: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> searchLocation(String query) async {
    try {
      setState(() => _searchSuggestions = []);
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search')
          .replace(queryParameters: {
            'q': query,
            'format': 'json',
            'addressdetails': '1',
            'limit': '1',
          }),
        headers: {'User-Agent': 'Flutter_Map_App'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final place = data.first;
          final lat = double.parse(place['lat']);
          final lon = double.parse(place['lon']);
          final displayName = place['display_name'] as String;
          final address = place['address'] as Map<String, dynamic>;
          
          final LatLng searchResult = LatLng(lat, lon);
          
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
                        name: displayName,
                        rating: 0.0,
                        openStatus: address['type'] ?? 'Unknown',
                        imageUrl: null,
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
        } else {
          throw Exception('No results found');
        }
      } else {
        throw Exception('Failed to load search results');
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
          if (_routePoints.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (_routeDistance != null && _routeDuration != null) {
                  showMaterialModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => RouteDetails(
                      distance: _routeDistance!,
                      duration: _routeDuration!,
                    ),
                  );
                }
              },
              child: PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5,
                    color: Colors.red.withOpacity(0.8),
                    borderStrokeWidth: 3,
                    borderColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
        ],
      ),
      Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 25),
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
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            _markers.clear();
                            _searchSuggestions = [];
                            _routePoints = []; // Clear polyline when search is closed
                          });
                        },
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    _getSuggestions(value);
                  });
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    searchLocation(value);
                  }
                },
              ),
              if (_searchSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _searchSuggestions[index];
                      return ListTile(
                        title: Text(
                          suggestion['display_name'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          searchController.text = suggestion['display_name'] as String;
                          moveToLocation(
                            suggestion['lat'] as double,
                            suggestion['lon'] as double,
                          );
                          setState(() => _searchSuggestions = []);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ]);
  }
}

class RouteDetails extends StatelessWidget {
  final double distance;
  final double duration;

  const RouteDetails({
    Key? key,
    required this.distance,
    required this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route Information',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Distance',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.access_time, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${duration.toStringAsFixed(0)} min',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_map_app/widgets/bottom_nav_bar.dart';
import 'package:flutter_map_app/widgets/map_view.dart';
import 'package:flutter_map_app/widgets/search_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<MapViewState> _mapViewKey = GlobalKey<MapViewState>();

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onVoicePressed() {
    // TODO: Implement voice search functionality
  }

  void _onSearchPressed() {
    // TODO: Implement location search functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MapView(key: _mapViewKey),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: CustomSearchBar(
              controller: _searchController,
              onVoicePressed: _onVoicePressed,
              onSearchPressed: _onSearchPressed,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            _mapViewKey.currentState?.getCurrentLocation();
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

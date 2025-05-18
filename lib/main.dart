import 'package:flutter/material.dart';
import 'package:jalurku/widgets/bottom_nav_bar.dart';
import 'package:jalurku/widgets/map_view.dart';
import 'package:jalurku/pages/bookmark_page.dart';
import 'package:jalurku/pages/notification_page.dart';
import 'package:jalurku/pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JalurKu',
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
  final GlobalKey<MapViewState> _mapViewKey = GlobalKey<MapViewState>();

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Stack(
            fit: StackFit.expand,
            children: [
              MapView(key: _mapViewKey),
            ],
          ),
          const NotificationPage(),
          const BookmarkPage(),
          const SettingsPage()
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
}

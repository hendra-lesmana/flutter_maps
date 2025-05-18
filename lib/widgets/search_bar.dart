import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onVoicePressed;
  final VoidCallback onSearchPressed;

  final Function(double lat, double lon)? onLocationFound;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.onVoicePressed,
    required this.onSearchPressed,
    this.onLocationFound,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();

}

class _CustomSearchBarState extends State<CustomSearchBar> {
  bool _isLoading = false;

  Future<void> _searchLocation() async {
    final query = widget.controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty && widget.onLocationFound != null) {
        final location = locations.first;
        widget.onLocationFound!(location.latitude, location.longitude);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        onSubmitted: (_) => _searchLocation(),
        decoration: InputDecoration(
          hintText: 'Search location...',
          prefixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: _isLoading ? null : _searchLocation,
          ),
          suffixIcon: _isLoading
              ? Container(
                  padding: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: widget.onVoicePressed,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
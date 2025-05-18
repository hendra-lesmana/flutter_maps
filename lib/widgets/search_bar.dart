import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty && widget.onLocationFound != null) {
          final location = results.first;
          widget.onLocationFound!(
            double.parse(location['lat']),
            double.parse(location['lon']),
          );
        } else {
          throw Exception('No results found');
        }
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location not found: ${e.toString()}')),
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
import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onVoicePressed;
  final VoidCallback onSearchPressed;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.onVoicePressed,
    required this.onSearchPressed,
  }) : super(key: key);

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
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search location...',
          prefixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchPressed,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic),
            onPressed: onVoicePressed,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
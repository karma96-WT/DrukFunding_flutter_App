import 'package:flutter/material.dart';
import 'package:drukfunding/model/Project.dart ';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Set the title widget to a TextField
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: TextField(
                decoration: InputDecoration(
                  // Hint text inside the search bar
                  hintText: 'Search for projects...',
                  border: InputBorder.none,
                  // Leading search icon
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  // Optional clear button
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      // Handle clear action, perhaps clear a TextEditingController
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                ),
                onChanged: (value) {
                  // Call your search/filter function here
                  print('Search query: $value');
                },
              ),
            ),
          ),
        ),
        // Optional: Remove default title padding/constraints
        titleSpacing: 0,
        backgroundColor: Colors.blue,
      ),
      body: const Center(child: Text('Content filtered by search')),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiItem {
  final int id;
  final String title;
  final String body;

  const ApiItem({required this.id, required this.title, required this.body});

  factory ApiItem.fromJson(Map<String, dynamic> json) {
    return ApiItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'No title',
      body: json['body'] as String? ?? '',
    );
  }
}

class SamplePage extends StatefulWidget {
  final http.Client? client;

  const SamplePage({super.key, this.client});

  @override
  State<SamplePage> createState() => _SamplePageState();
}

class _SamplePageState extends State<SamplePage> {
  late final http.Client _client;
  late Future<List<ApiItem>> _itemsFuture;
  List<ApiItem> _items = [];

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _itemsFuture = _fetchItems();
  }

  Future<List<ApiItem>> _fetchItems() async {
    final response = await _client.get(
      Uri.parse('https://jsonplaceholder.typicode.com/posts'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load items');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    final items = data
        .map((item) => ApiItem.fromJson(item as Map<String, dynamic>))
        .toList();

    _items = items;
    return items;
  }

  Future<void> _deleteItem(ApiItem item) async {
    try {
      final response = await _client.delete(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/${item.id}'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete item');
      }

      if (!mounted) return;

      setState(() {
        _items.removeWhere((currentItem) => currentItem.id == item.id);
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete item: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ApiItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading items: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final items = _items.isNotEmpty
            ? _items
            : snapshot.data ?? const <ApiItem>[];

        if (items.isEmpty) {
          return const Center(child: Text('No items available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(item.body, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _deleteItem(item),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

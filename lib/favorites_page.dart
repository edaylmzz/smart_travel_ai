 import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> favorites = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final savedRoutes =
        prefs.getStringList("favorite_routes") ?? [];

    setState(() {
      favorites = savedRoutes
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> deleteFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();

    favorites.removeAt(index);

    final updatedList =
        favorites.map((e) => jsonEncode(e)).toList();

    await prefs.setStringList(
      "favorite_routes",
      updatedList,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorilerim"),
      ),
      body: favorites.isEmpty
          ? const Center(
              child: Text("Henüz favori rota yok"),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];

                return Card(
                  child: ListTile(
                    title: Text(
                      "${item["city"]}",
                    ),
                    subtitle: Text(
                      "${item["interest"]} • ${item["duration"]}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        deleteFavorite(index);
                      },
                    ),
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RouteResultPage(
        city: item["city"],
        interest: item["interest"],
        day: item["duration"],
        routeText: item["routeText"],
        weather: item["weatherInfo"],
      ),
    ),
  );
},
                  ),
                );
              },
            ),
    );
  }
}
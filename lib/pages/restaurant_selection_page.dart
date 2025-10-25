import 'package:flutter/material.dart';
import '../data/restaurant_models.dart';
import '../data/datastore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RestaurantSelectionPage extends StatefulWidget {
  const RestaurantSelectionPage({Key? key}) : super(key: key);

  @override
  State<RestaurantSelectionPage> createState() => _RestaurantSelectionPageState();
}

class _RestaurantSelectionPageState extends State<RestaurantSelectionPage> {
  List<Restaurant> restaurants = [];
  List<Restaurant> deletedRestaurants = [];
  Restaurant? selectedRestaurant;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    final restaurantsJson = prefs.getString('restaurants') ?? '[]';
    final List<dynamic> restaurantsList = json.decode(restaurantsJson);
    
    setState(() {
      restaurants = restaurantsList
          .map((r) => Restaurant.fromJson(r))
          .where((r) => !r.isDeleted)
          .toList();
      deletedRestaurants = restaurantsList
          .map((r) => Restaurant.fromJson(r))
          .where((r) => r.isDeleted)
          .toList();
      selectedRestaurant = restaurants.isNotEmpty ? restaurants.first : null;
    });
  }

  Future<void> _saveRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    final allRestaurants = [...restaurants, ...deletedRestaurants];
    await prefs.setString('restaurants', json.encode(allRestaurants.map((r) => r.toJson()).toList()));
  }

  Future<void> _addRestaurant() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Restaurant'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Restaurant Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, _nameController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null) {
      final restaurant = Restaurant(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        createdDate: DateTime.now(),
      );
      setState(() {
        restaurants.add(restaurant);
        selectedRestaurant = restaurant;
      });
      await _saveRestaurants();
      _nameController.clear();
    }
  }

  Future<void> _deleteRestaurant(Restaurant restaurant) async {
    final store = await DataStore.instanceInit(restaurantId: restaurant.id);
    final unpaidBills = store.bills.where((b) => !b.isPaid).toList();
    final unpaidSalaries = store.staff.where((s) => !s.isPaid).toList();
    
    if (unpaidBills.isNotEmpty || unpaidSalaries.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Restaurant'),
          content: Text(
            'Cannot delete "${restaurant.name}" because it has:\n'
            '${unpaidBills.isNotEmpty ? '• ${unpaidBills.length} unpaid bills\n' : ''}'
            '${unpaidSalaries.isNotEmpty ? '• ${unpaidSalaries.length} unpaid salaries\n' : ''}'
            'Please clear all pending payments first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content: Text('Are you sure you want to delete "${restaurant.name}"? History will be preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        restaurants.remove(restaurant);
        restaurant.isDeleted = true;
        deletedRestaurants.add(restaurant);
        if (selectedRestaurant?.id == restaurant.id) {
          selectedRestaurant = restaurants.isNotEmpty ? restaurants.first : null;
        }
      });
      await _saveRestaurants();
    }
  }

  Future<void> _enterRestaurant() async {
    if (selectedRestaurant == null) return;
    
    final store = await DataStore.instanceInit(restaurantId: selectedRestaurant!.id);
    
    Navigator.pushReplacementNamed(
      context,
      '/main',
      arguments: {'store': store, 'restaurant': selectedRestaurant},
    );
  }

  Future<void> _viewDeletedRestaurant(Restaurant restaurant) async {
    final store = await DataStore.instanceInit(restaurantId: restaurant.id);
    
    Navigator.pushNamed(
      context,
      '/dashboard',
      arguments: {'store': store, 'restaurant': restaurant},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Restaurant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Restaurant:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Restaurant>(
                      value: selectedRestaurant,
                      items: restaurants.map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.name),
                      )).toList(),
                      onChanged: (r) => setState(() => selectedRestaurant = r),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: selectedRestaurant != null ? _enterRestaurant : null,
                            icon: const Icon(Icons.login),
                            label: const Text('Enter'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _addRestaurant,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: selectedRestaurant != null ? () => _deleteRestaurant(selectedRestaurant!) : null,
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (deletedRestaurants.isNotEmpty) ...[
              const Text('Deleted Restaurants:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: deletedRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = deletedRestaurants[index];
                    return Card(
                      color: Colors.grey.shade200,
                      child: ListTile(
                        title: Text(restaurant.name),
                        subtitle: const Text('Deleted - History preserved'),
                        trailing: ElevatedButton(
                          onPressed: () => _viewDeletedRestaurant(restaurant),
                          child: const Text('View Dashboard'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
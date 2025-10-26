import 'package:flutter/material.dart';
import '../data/datastore.dart';
import '../data/restaurant_models.dart';
import 'dashboard_page.dart';

class DeletedRestaurantDashboard extends StatelessWidget {
  final DataStore store;
  final Restaurant restaurant;

  const DeletedRestaurantDashboard({
    Key? key,
    required this.store,
    required this.restaurant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${restaurant.name} (Deleted)'),
        backgroundColor: Colors.grey.shade300,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: const Text(
              'This restaurant has been deleted. You can only view the dashboard.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: DashboardPage(store: store, restaurantName: restaurant.name),
          ),
        ],
      ),
    );
  }
}
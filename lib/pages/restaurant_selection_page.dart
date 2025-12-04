import 'package:flutter/material.dart';
import '../data/restaurant_models.dart';
import '../data/datastore.dart';
import '../data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

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

  Future<void> _exportAllData() async {
    try {
      final allData = <String, dynamic>{
        'restaurants': [...restaurants, ...deletedRestaurants].map((r) => r.toJson()).toList(),
        'restaurantData': <String, dynamic>{},
      };

      for (final restaurant in [...restaurants, ...deletedRestaurants]) {
        final store = await DataStore.instanceInit(restaurantId: restaurant.id);
        (allData['restaurantData'] as Map<String, dynamic>)[restaurant.id] = {
          'bills': store.bills.map((b) => b.toJson()).toList(),
          'sales': store.sales.map((s) => s.toJson()).toList(),
          'staff': store.staff.map((s) => s.toJson()).toList(),
          'staffDetails': store.staffDetails.map((s) => s.toJson()).toList(),
          'categories': store.categories,
        };
      }

      final jsonString = jsonEncode(allData);
      final fileName = 'all_restaurants_${DateTime.now().millisecondsSinceEpoch}.json';
      
      if (Platform.isAndroid || Platform.isIOS) {
        final directory = Platform.isAndroid 
            ? Directory('/storage/emulated/0/Download')
            : await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported to: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importData() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'JSON files',
        extensions: <String>['json'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      
      if (file == null) return;
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (data['restaurants'] != null) {
        final importedRestaurants = (data['restaurants'] as List)
            .map((r) => Restaurant.fromJson(r))
            .toList();
        
        for (final restaurant in importedRestaurants) {
          if (!restaurants.any((r) => r.id == restaurant.id) && 
              !deletedRestaurants.any((r) => r.id == restaurant.id)) {
            if (restaurant.isDeleted) {
              deletedRestaurants.add(restaurant);
            } else {
              restaurants.add(restaurant);
            }
          }
        }
        
        await _saveRestaurants();
      }
      
      if (data['restaurantData'] != null) {
        final restaurantData = data['restaurantData'] as Map<String, dynamic>;
        
        for (final entry in restaurantData.entries) {
          final restaurantId = entry.key;
          final storeData = entry.value as Map<String, dynamic>;
          
          final store = await DataStore.instanceInit(restaurantId: restaurantId);
          
          if (storeData['bills'] != null) {
            final importedBills = (storeData['bills'] as List)
                .map((e) => Bill.fromJson(e as Map<String, dynamic>))
                .toList();
            for (final bill in importedBills) {
              store.bills.add(bill);
            }
            await store.saveBills();
          }
          
          if (storeData['sales'] != null) {
            final importedSales = (storeData['sales'] as List)
                .map((e) => DailySales.fromJson(e as Map<String, dynamic>))
                .toList();
            for (final sale in importedSales) {
              store.sales.add(sale);
            }
            await store.saveSales();
          }
          
          if (storeData['staff'] != null) {
            final importedStaff = (storeData['staff'] as List)
                .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
                .toList();
            for (final staff in importedStaff) {
              store.staff.add(staff);
            }
            await store.saveStaff();
          }
          
          if (storeData['staffDetails'] != null) {
            final importedStaffDetails = (storeData['staffDetails'] as List)
                .map((e) => StaffDetails.fromJson(e as Map<String, dynamic>))
                .toList();
            for (final staffDetail in importedStaffDetails) {
              store.staffDetails.add(staffDetail);
            }
            await store.saveStaffDetails();
          }
          
          if (storeData['categories'] != null) {
            final importedCategories = List<String>.from(storeData['categories']);
            store.categories.addAll(importedCategories.where((c) => !store.categories.contains(c)));
            await store.saveCategories();
          }
        }
      }
      
      setState(() {
        selectedRestaurant = restaurants.isNotEmpty ? restaurants.first : null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data imported successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text('Select Restaurant'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Restaurant Manager',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Manage your restaurant finances',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Select Restaurant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                    ),
                    child: DropdownButtonFormField<Restaurant>(
                      value: selectedRestaurant,
                      items: restaurants.map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.name),
                      )).toList(),
                      onChanged: (r) => setState(() => selectedRestaurant = r),
                      decoration: const InputDecoration(
                        labelText: 'Choose Restaurant',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _addRestaurant,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add New'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: selectedRestaurant != null ? () => _deleteRestaurant(selectedRestaurant!) : null,
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: selectedRestaurant != null ? _enterRestaurant : null,
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      label: const Text(
                        'Enter Restaurant',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Restaurant Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Data & History',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.download, color: Color(0xFF10B981)),
                      ),
                      title: const Text('Export Data'),
                      subtitle: const Text('Export all restaurant data'),
                      onTap: () {
                        Navigator.pop(context);
                        _exportAllData();
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.upload, color: Color(0xFFF59E0B)),
                      ),
                      title: const Text('Import Data'),
                      subtitle: const Text('Import restaurant data'),
                      onTap: () {
                        Navigator.pop(context);
                        _importData();
                      },
                    ),
                    const Divider(height: 40),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.history, color: Colors.grey.shade600),
                      ),
                      title: const Text('Deleted Restaurants'),
                      subtitle: Text('${deletedRestaurants.length} deleted restaurants'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        _showDeletedRestaurants();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletedRestaurants() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Deleted Restaurants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: deletedRestaurants.isEmpty
                  ? const Center(
                      child: Text(
                        'No deleted restaurants',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: deletedRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = deletedRestaurants[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.restaurant_outlined,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'DELETED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _viewDeletedRestaurant(restaurant);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
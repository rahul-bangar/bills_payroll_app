import 'package:flutter/material.dart';
import 'data/datastore.dart';
import 'data/restaurant_models.dart';
import 'pages/daily_bills_page.dart';
import 'pages/daily_sales_page.dart';
import 'pages/weekly_bills_page.dart';
import 'pages/staff_salary_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/restaurant_selection_page.dart';
import 'pages/deleted_restaurant_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bills & Payroll',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          elevation: 2,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
          fillColor: Color(0xFFF5F6FA),
        ),
      ),
      home: const RestaurantSelectionPage(),
      routes: {
        '/main': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MainPage(
            store: args['store'] as DataStore,
            restaurant: args['restaurant'] as Restaurant,
          );
        },
        '/dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DeletedRestaurantDashboard(
            store: args['store'] as DataStore,
            restaurant: args['restaurant'] as Restaurant,
          );
        },
      },
    );
  }
}

class MainPage extends StatefulWidget {
  final DataStore store;
  final Restaurant restaurant;
  const MainPage({Key? key, required this.store, required this.restaurant}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardPage(store: widget.store),
          DailySalesPage(store: widget.store),
          DailyBillsPage(store: widget.store),
          WeeklyBillsPage(store: widget.store),
          StaffSalaryPage(store: widget.store),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Daily Bills'),
          NavigationDestination(icon: Icon(Icons.calendar_view_week), label: 'Weekly Bills'),
          NavigationDestination(icon: Icon(Icons.people_alt), label: 'Staff'),
        ],
      ),
    );
  }
}

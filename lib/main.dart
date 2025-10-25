import 'package:flutter/material.dart';
import 'data/datastore.dart';
import 'pages/daily_bills_page.dart';
import 'pages/weekly_bills_page.dart';
import 'pages/staff_salary_page.dart';
import 'pages/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await DataStore.instanceInit();
  runApp(MyApp(store: store));
}

class MyApp extends StatefulWidget {
  final DataStore store;
  const MyApp({Key? key, required this.store}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  static const _title = 'Bills & Payroll';

  @override
  Widget build(BuildContext context) {
    final colorSeed = Colors.indigo;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: colorSeed),
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

      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            DailyBillsPage(store: widget.store),
            WeeklyBillsPage(store: widget.store),
            StaffSalaryPage(store: widget.store),
            DashboardPage(store: widget.store),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Daily'),
            NavigationDestination(icon: Icon(Icons.calendar_view_week), label: 'Weekly'),
            NavigationDestination(icon: Icon(Icons.people_alt), label: 'Staff'),
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          ],
        ),
      ),
    );
  }
}

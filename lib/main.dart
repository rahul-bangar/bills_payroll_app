// ---------------- lib/main.dart ----------------
import 'package:flutter/material.dart';
import 'data/datastore.dart';
import 'pages/daily_bills_page.dart';
import 'pages/weekly_bills_page.dart';
import 'pages/staff_salary_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
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
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bills & Payroll',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: Text('Bills & Payroll')),
        body: IndexedStack(
          index: _index,
          children: [
            DailyBillsPage(store: widget.store),
            WeeklyBillsPage(store: widget.store),
            StaffSalaryPage(store: widget.store),
            DashboardPage(store: widget.store),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          selectedItemColor: Colors.indigo,       // Color of the selected item
          unselectedItemColor: Colors.grey,       // Color of unselected items
          backgroundColor: Colors.white,          // Background color of the bar
          type: BottomNavigationBarType.fixed,    // Ensures all items are shown
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Daily'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_view_week), label: 'Weekly'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          ],
        ),
      ),
    );
  }
}
// ---------------- lib/pages/dashboard_page.dart ----------------
import 'package:flutter/material.dart';
import '../data/datastore.dart';

class DashboardPage extends StatelessWidget {
  final DataStore store;
  const DashboardPage({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalSales = store.sales.fold(0.0, (p, s) => p + s.totalSales);
    final totalExpenses = store.bills.fold(0.0, (p, b) => p + b.value);
    final totalSalary = store.staff.fold(0.0, (p, s) => p + s.payable(DateTime.now().month, DateTime.now().year));
    final profitOrLoss = totalSales - totalExpenses - totalSalary;

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Card(
            child: ListTile(title: Text('Total Sales'), trailing: Text(totalSales.toStringAsFixed(2))),
          ),
          Card(
            child: ListTile(title: Text('Total Expenses'), trailing: Text(totalExpenses.toStringAsFixed(2))),
          ),
          Card(
            child: ListTile(title: Text('Total Salary'), trailing: Text(totalSalary.toStringAsFixed(2))),
          ),
          Card(
            color: profitOrLoss >=0 ? Colors.green[100] : Colors.red[100],
            child: ListTile(title: Text('Profit / Loss'), trailing: Text(profitOrLoss.toStringAsFixed(2))),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final path = await store.exportCsv();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('CSV exported to: $path')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to export CSV: $e')),
                );
              }
            },
            icon: Icon(Icons.download),
            label: Text('Export CSV'),
          ),
        ],
      ),
    );
  }
}
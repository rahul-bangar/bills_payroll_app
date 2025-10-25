// ---------------- lib/pages/dashboard_page.dart ----------------
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/datastore.dart';

class DashboardPage extends StatefulWidget {
  final DataStore store;
  const DashboardPage({Key? key, required this.store}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _monthlyView = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    // --- Sales ---
    final sales = (_monthlyView
            ? widget.store.sales.where((s) =>
                s.date.year == _selectedMonth.year &&
                s.date.month == _selectedMonth.month)
            : widget.store.sales)
        .toList();
    final totalSales = sales.fold(0.0, (p, s) => p + s.totalSales);

    // --- Bills ---
    final bills = (_monthlyView
            ? widget.store.bills.where((b) =>
                b.date.year == _selectedMonth.year &&
                b.date.month == _selectedMonth.month)
            : widget.store.bills)
        .toList();
    final totalExpenses = bills.fold(0.0, (p, b) => p + b.value);

    // --- Staff salaries ---
    final staffList = _monthlyView
        ? widget.store.staff.where((s) =>
            s.date.year == _selectedMonth.year &&
            s.date.month == _selectedMonth.month)
        : widget.store.staff;

    final totalSalary = staffList.fold(
        0.0,
        (sum, s) => sum +
            s.payable(_monthlyView ? _selectedMonth.month : s.date.month,
                _monthlyView ? _selectedMonth.year : s.date.year)+s.advancePaid);

    final profitOrLoss = totalSales - totalExpenses - totalSalary;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // --- Toggle Overall / Monthly ---
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Overall'),
                  value: false,
                  groupValue: _monthlyView,
                  onChanged: (v) => setState(() => _monthlyView = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Monthly'),
                  value: true,
                  groupValue: _monthlyView,
                  onChanged: (v) => setState(() => _monthlyView = v!),
                ),
              ),
            ],
          ),

          if (_monthlyView)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickMonth,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Change'),
                ),
              ],
            ),

          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Total Sales'),
              trailing: Text(totalSales.toStringAsFixed(2)),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Total Expenses'),
              trailing: Text(totalExpenses.toStringAsFixed(2)),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Total Salary'),
              trailing: Text(totalSalary.toStringAsFixed(2)),
            ),
          ),
          Card(
            color: profitOrLoss >= 0 ? Colors.green[100] : Colors.red[100],
            child: ListTile(
              title: const Text('Profit / Loss'),
              trailing: Text(profitOrLoss.toStringAsFixed(2)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final path = await widget.store.exportCsv();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('CSV exported to: $path')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to export CSV: $e')),
                );
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      selectableDayPredicate: (date) => date.day == 1,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }
}

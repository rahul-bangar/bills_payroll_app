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
  String _selectedView = 'Overall';
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  bool _showUnpaidDetails = false;
  bool _showWeeklyUnpaidDetails = false;
  bool _showDailyUnpaidDetails = false;
  bool _showUnpaidSalariesDetails = false;

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // --- Filter data based on selected view ---
    final sales = _getFilteredSales();
    final totalSales = sales.fold(0.0, (p, s) => p + s.totalSales);

    final bills = _getFilteredBills();

    final paidExpenses = bills.where((b) => b.isPaid).fold(0.0, (p, b) => p + b.value);
    final pendingExpenses = bills.where((b) => !b.isPaid).fold(0.0, (p, b) => p + b.value);

    // --- Staff salaries ---
    final staffList = _getFilteredStaff();
    final paidSalaries = staffList.where((s) => s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);
    final unpaidSalaries = staffList.where((s) => !s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);
    final totalSalary = paidSalaries + unpaidSalaries;

    final profitOrLoss = totalSales - paidExpenses - paidSalaries;

    // Check for unpaid bills from previous days (exclude weekly bills)
    final today = DateTime.now();
    final unpaidBillDates = widget.store.bills
        .where((b) => !b.isPaid && !b.isWeekly && b.date.isBefore(DateTime(today.year, today.month, today.day)))
        .map((b) => b.date)
        .toSet()
        .toList();
    unpaidBillDates.sort((a, b) => a.compareTo(b));

    // Check for unpaid weekly bills
    final unpaidWeeklyBills = widget.store.bills
        .where((b) => !b.isPaid && b.isWeekly)
        .toList();

    // Check for unpaid daily bills for today
    final unpaidDailyBills = widget.store.bills
        .where((b) => !b.isPaid && 
               !b.isWeekly && 
               DateFormat('yyyy-MM-dd').format(b.date) == 
               DateFormat('yyyy-MM-dd').format(today))
        .toList();

    // Check for unpaid salaries from previous months
    final currentMonth = DateTime(today.year, today.month, 1);
    final unpaidSalariesFromPreviousMonths = widget.store.staff
        .where((s) => !s.isPaid && 
               DateTime(s.date.year, s.date.month, 1).isBefore(currentMonth))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Refresh the dashboard
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          const Text('Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Unpaid Bills Warning Banner
          if (unpaidBillDates.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showUnpaidDetails = !_showUnpaidDetails),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unpaid Bills Alert!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                          Icon(
                            _showUnpaidDetails ? Icons.expand_less : Icons.expand_more,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showUnpaidDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: unpaidBillDates.map((date) {
                          final billsForDate = widget.store.bills
                              .where((b) => !b.isPaid && !b.isWeekly && 
                                     DateFormat('yyyy-MM-dd').format(b.date) == 
                                     DateFormat('yyyy-MM-dd').format(date))
                              .toList();
                          final totalUnpaid = billsForDate.fold(0.0, (sum, b) => sum + b.value);
                          
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(date)} - ₹${totalUnpaid.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...billsForDate.map((bill) => Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 2),
                                  child: Text('• ${bill.category}: ₹${bill.value.toStringAsFixed(2)}'),
                                )),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // Weekly Unpaid Bills Warning Banner
          if (unpaidWeeklyBills.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showWeeklyUnpaidDetails = !_showWeeklyUnpaidDetails),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'WEEKLY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unpaid Weekly Bills!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                          Icon(
                            _showWeeklyUnpaidDetails ? Icons.expand_less : Icons.expand_more,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showWeeklyUnpaidDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: unpaidWeeklyBills.map((bill) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${bill.category}: ₹${bill.value.toStringAsFixed(2)} (Added: ${DateFormat('dd MMM yyyy').format(bill.date)})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // Daily Unpaid Bills Warning Banner
          if (unpaidDailyBills.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showDailyUnpaidDetails = !_showDailyUnpaidDetails),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.today, color: Colors.blue),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DAILY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unpaid Daily Bills for Today!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          Icon(
                            _showDailyUnpaidDetails ? Icons.expand_less : Icons.expand_more,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showDailyUnpaidDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: unpaidDailyBills.map((bill) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${bill.category}: ₹${bill.value.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // Unpaid Salaries Warning Banner
          if (unpaidSalariesFromPreviousMonths.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                border: Border.all(color: Colors.purple),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showUnpaidSalariesDetails = !_showUnpaidSalariesDetails),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.purple),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SALARY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unpaid Salaries from Previous Months!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                          ),
                          Icon(
                            _showUnpaidSalariesDetails ? Icons.expand_less : Icons.expand_more,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showUnpaidSalariesDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: unpaidSalariesFromPreviousMonths.map((staff) {
                          final payableAmount = staff.payable(staff.date.month, staff.date.year).toDouble() + staff.advancePaid;
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${staff.name}: ₹${payableAmount.toStringAsFixed(2)} (${DateFormat('MMM yyyy').format(staff.date)})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // --- View Selector ---
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedView,
                  items: ['Overall', 'Monthly', 'Weekly', 'Daily']
                      .map((view) => DropdownMenuItem(
                            value: view,
                            child: Text(view),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedView = value!),
                  decoration: const InputDecoration(
                    labelText: 'View',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_selectedView != 'Overall')
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Change'),
                ),
            ],
          ),

          if (_selectedView != 'Overall')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _getDateRangeText(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
              title: const Text('Paid Expenses'),
              trailing: Text(paidExpenses.toStringAsFixed(2)),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Pending Expenses'),
              trailing: Text(pendingExpenses.toStringAsFixed(2)),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Paid Salaries'),
              trailing: Text(paidSalaries.toStringAsFixed(2)),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Unpaid Salaries'),
              trailing: Text(unpaidSalaries.toStringAsFixed(2)),
            ),
          ),
          Card(
            color: profitOrLoss >= 0 ? Colors.green[100] : Colors.red[100],
            child: ListTile(
              title: const Text('Profit / Loss'),
              trailing: Text(profitOrLoss.toStringAsFixed(2)),
            ),
          ),
          const SizedBox(height: 12),
          _buildExpenseChart(bills),
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
          ],
        ),
      ),
    );
  }

  List<dynamic> _getFilteredSales() {
    switch (_selectedView) {
      case 'Daily':
        return widget.store.sales.where((s) => 
          DateFormat('yyyy-MM-dd').format(s.date) == 
          DateFormat('yyyy-MM-dd').format(_selectedDate)).toList();
      case 'Weekly':
        final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
        return widget.store.sales.where((s) => 
          !s.date.isBefore(_selectedWeekStart) && 
          !s.date.isAfter(weekEnd)).toList();
      case 'Monthly':
        return widget.store.sales.where((s) =>
          s.date.year == _selectedMonth.year &&
          s.date.month == _selectedMonth.month).toList();
      default:
        return widget.store.sales;
    }
  }

  List<dynamic> _getFilteredBills() {
    switch (_selectedView) {
      case 'Daily':
        return widget.store.bills.where((b) => 
          DateFormat('yyyy-MM-dd').format(b.date) == 
          DateFormat('yyyy-MM-dd').format(_selectedDate)).toList();
      case 'Weekly':
        final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
        return widget.store.bills.where((b) => 
          !b.date.isBefore(_selectedWeekStart) && 
          !b.date.isAfter(weekEnd)).toList();
      case 'Monthly':
        return widget.store.bills.where((b) =>
          b.date.year == _selectedMonth.year &&
          b.date.month == _selectedMonth.month).toList();
      default:
        return widget.store.bills;
    }
  }

  List<dynamic> _getFilteredStaff() {
    switch (_selectedView) {
      case 'Daily':
        return widget.store.staff.where((s) => 
          DateFormat('yyyy-MM-dd').format(s.date) == 
          DateFormat('yyyy-MM-dd').format(_selectedDate)).toList();
      case 'Weekly':
        final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
        return widget.store.staff.where((s) => 
          !s.date.isBefore(_selectedWeekStart) && 
          !s.date.isAfter(weekEnd)).toList();
      case 'Monthly':
        return widget.store.staff.where((s) =>
          s.date.year == _selectedMonth.year &&
          s.date.month == _selectedMonth.month).toList();
      default:
        return widget.store.staff;
    }
  }

  String _getDateRangeText() {
    switch (_selectedView) {
      case 'Daily':
        return 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}';
      case 'Weekly':
        final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
        return 'Week: ${DateFormat('MMM dd').format(_selectedWeekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
      case 'Monthly':
        return 'Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}';
      default:
        return '';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedView == 'Monthly' ? _selectedMonth : 
                   _selectedView == 'Weekly' ? _selectedWeekStart : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        switch (_selectedView) {
          case 'Daily':
            _selectedDate = picked;
            break;
          case 'Weekly':
            _selectedWeekStart = _getWeekStart(picked);
            break;
          case 'Monthly':
            _selectedMonth = DateTime(picked.year, picked.month, 1);
            break;
        }
      });
    }
  }

  Widget _buildExpenseChart(List<dynamic> bills) {
    if (bills.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No expenses to display in chart'),
        ),
      );
    }

    final categoryTotals = <String, double>{};
    for (final bill in bills) {
      categoryTotals[bill.category] = (categoryTotals[bill.category] ?? 0) + bill.value;
    }

    if (categoryTotals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No expenses to display in chart'),
        ),
      );
    }

    final maxValue = categoryTotals.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expenses by Category (${_getDateRangeText()})', 
                 style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...categoryTotals.entries.map((entry) {
              final percentage = entry.value / maxValue;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('₹${entry.value.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

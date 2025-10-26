import 'package:flutter/material.dart';
import '../data/datastore.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

class DailyBillsPage extends StatefulWidget {
  final DataStore store;
  final String restaurantName;
  const DailyBillsPage({Key? key, required this.store, required this.restaurantName}) : super(key: key);

  @override
  State<DailyBillsPage> createState() => _DailyBillsPageState();
}

class _DailyBillsPageState extends State<DailyBillsPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  final _billValueCtrl = TextEditingController();
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.store.categories.isNotEmpty
        ? widget.store.categories.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final billsForDate = widget.store.bills
        .where(
          (b) =>
              DateFormat('yyyy-MM-dd').format(b.date) ==
                  DateFormat('yyyy-MM-dd').format(selectedDate) &&
              !b.isWeekly,
        )
        .toList();

    final paidBills = billsForDate.where((b) => b.isPaid).fold(0.0, (sum, b) => sum + b.value);
    final unpaidBills = billsForDate.where((b) => !b.isPaid).fold(0.0, (sum, b) => sum + b.value);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          // --- Date Picker Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Add Bill Card ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Bill',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          items: widget.store.categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => selectedCategory = v),
                          decoration: const InputDecoration(
                            label: Text('Category'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _billValueCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Value'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addBill,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Paid Bills Summary
          Card(
            color: Colors.green.shade50,
            child: ListTile(
              title: const Text(
                'Paid Bills for Day',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹${paidBills.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Unpaid Bills Summary
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              title: const Text(
                'Unpaid Bills for Day',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹${unpaidBills.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- View Toggle and Export ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bills for the day',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Export PDF',
                  ),
                  ToggleButtons(
                    isSelected: [!_showChart, _showChart],
                    onPressed: (index) => setState(() => _showChart = index == 1),
                    children: const [
                      Icon(Icons.list),
                      Icon(Icons.bar_chart),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Bills Content ---
          if (_showChart)
            _buildChart(billsForDate)
          else
            ..._buildBillsList(billsForDate),

        ],
      ),
    );
  }

  // --- Pick Date ---
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => selectedDate = d);
    }
  }

  // --- Add Bill ---
  List<Widget> _buildBillsList(List<Bill> billsForDate) {
    return billsForDate.map((b) {
      return Card(
        child: ListTile(
          title: Text(b.category),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Value: ₹${b.value.toStringAsFixed(2)}'),
              Text(
                b.isPaid ? 'Status: Paid' : 'Status: Pending',
                style: TextStyle(
                  color: b.isPaid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check_circle,
                    color: b.isPaid ? Colors.green : Colors.grey),
                onPressed: () async {
                  b.isPaid = !b.isPaid;
                  await widget.store.updateBill(b);
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await widget.store.deleteBill(b.id);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bill deleted')),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildChart(List<Bill> billsForDate) {
    if (billsForDate.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No bills to display in chart'),
        ),
      );
    }

    final categoryTotals = <String, double>{};
    for (final bill in billsForDate) {
      categoryTotals[bill.category] = (categoryTotals[bill.category] ?? 0) + bill.value;
    }

    final maxValue = categoryTotals.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bills by Category', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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

  Future<void> _addBill() async {
    final val = double.tryParse(_billValueCtrl.text);
    if (val == null || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid bill value and category')),
      );
      return;
    }
    final b = Bill(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      date: selectedDate,
      category: selectedCategory!,
      value: val,
      isWeekly: false,
    );
    await widget.store.addBill(b);
    _billValueCtrl.clear();
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bill added')));
  }

  Future<void> _exportPdf() async {
    try {
      final path = await widget.store.exportDailyBillsPdf(selectedDate, widget.restaurantName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF exported to: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e')),
      );
    }
  }
}

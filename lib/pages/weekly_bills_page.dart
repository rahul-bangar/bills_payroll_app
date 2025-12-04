import 'package:flutter/material.dart';
import '../data/datastore.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';

class WeeklyBillsPage extends StatefulWidget {
  final DataStore store;
  final String restaurantName;
  const WeeklyBillsPage({Key? key, required this.store, required this.restaurantName}) : super(key: key);

  @override
  State<WeeklyBillsPage> createState() => _WeeklyBillsPageState();
}

class _WeeklyBillsPageState extends State<WeeklyBillsPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  final List<BillItem> _billItems = [];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.store.categories.isNotEmpty
        ? widget.store.categories.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyBills = widget.store.bills.where((b) => b.isWeekly).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          // --- Week Picker Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week of: ${DateFormat('yyyy-MM-dd').format(_weekStart(selectedDate))}',
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

          // --- Add Weekly Bill Card ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Weekly Bill',
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
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
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
                      ElevatedButton.icon(
                        onPressed: _addBillItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_billItems.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._billItems.map(
                          (i) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(i.name),
                            trailing: Text('₹${i.amount.toStringAsFixed(2)}'),
                            leading: IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                setState(() => _billItems.remove(i));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addBill,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Weekly Bill'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Paid Weekly Bills Summary
          Card(
            color: Colors.green.shade50,
            child: ListTile(
              title: const Text(
                'Paid Weekly Bills',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹${weeklyBills.where((b) => b.isPaid).fold(0.0, (sum, b) => sum + b.value).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Unpaid Weekly Bills Summary
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              title: const Text(
                'Unpaid Weekly Bills',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹${weeklyBills.where((b) => !b.isPaid).fold(0.0, (sum, b) => sum + b.value).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly bills', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export PDF',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Weekly Bills List ---
          if (weeklyBills.isEmpty)
            Center(
              child: Text(
                'No weekly bills available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...weeklyBills.map((b) {
              return Card(
                child: ListTile(
                  title: Text('${b.category}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...b.items.map((i) =>
                          Text('${i.name}: ₹${i.amount.toStringAsFixed(2)}')),
                      Text('Total: ₹${b.value.toStringAsFixed(2)}'),
                      Text(
                        b.isPaid ? 'Status: Paid' : 'Status: Pending',
                        style: TextStyle(
                          color: b.isPaid ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Date: ${DateFormat('yyyy-MM-dd').format(b.date)}'),
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
                            const SnackBar(
                              content: Text('Weekly bill deleted'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  DateTime _weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => selectedDate = d);
  }

  Future<void> _addBillItem() async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Bill Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text);
              if (name.isNotEmpty && amount != null) {
                setState(() => _billItems.add(BillItem(name: name, amount: amount)));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBill() async {
    if (_billItems.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item and select category')),
      );
      return;
    }

    final totalValue = _billItems.fold<double>(0, (sum, i) => sum + i.amount);
    final b = Bill(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      date: selectedDate,
      category: selectedCategory!,
      value: totalValue,
      isWeekly: true,
      isPaid: false,
      items: List.from(_billItems),
    );

    await widget.store.addBill(b);
    _billItems.clear();
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Weekly bill added')));
  }

  Future<void> _exportPdf() async {
    try {
      final weekStart = _weekStart(selectedDate);
      final path = await widget.store.exportWeeklyBillsPdf(weekStart, widget.restaurantName);
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

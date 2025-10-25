import 'package:flutter/material.dart';
import '../data/datastore.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

class DailyBillsPage extends StatefulWidget {
  final DataStore store;
  const DailyBillsPage({Key? key, required this.store}) : super(key: key);

  @override
  State<DailyBillsPage> createState() => _DailyBillsPageState();
}

class _DailyBillsPageState extends State<DailyBillsPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  final _billValueCtrl = TextEditingController();
  final _salesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.store.categories.isNotEmpty
        ? widget.store.categories.first
        : null;
    _updateSalesController();
  }

  void _updateSalesController() {
    final todaySale = widget.store.sales.firstWhere(
      (s) =>
          DateFormat('yyyy-MM-dd').format(s.date) ==
          DateFormat('yyyy-MM-dd').format(selectedDate),
      orElse: () => DailySales(id: '', date: selectedDate, totalSales: 0),
    );
    _salesCtrl.text = todaySale.totalSales.toStringAsFixed(2);
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

    final todaySale = widget.store.sales.firstWhere(
      (s) =>
          DateFormat('yyyy-MM-dd').format(s.date) ==
          DateFormat('yyyy-MM-dd').format(selectedDate),
      orElse: () => DailySales(id: '', date: selectedDate, totalSales: 0),
    );

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

          // --- Daily Sales Input Card ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Sales',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _salesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total sales',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _saveSales,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Display Today's Sales as a separate card ---
          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              title: const Text(
                "Today's Sales",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '₹${todaySale.totalSales.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _salesCtrl.text = todaySale.totalSales.toStringAsFixed(2);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Edit sales in the field above and save')),
                      );
                    },
                  ),
                  if (todaySale.id.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteSales,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Bills List Header ---
          Text(
            'Bills for the day',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // --- Bills List ---
          ...billsForDate.map((b) {
            return Card(
              child: ListTile(
                title: Text(b.category),
                subtitle: Text('Value: ₹${b.value.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await widget.store.deleteBill(b.id);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bill deleted')),
                    );
                  },
                ),
              ),
            );
          }).toList(),
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
      setState(() {
        selectedDate = d;
        _updateSalesController();
      });
    }
  }

  // --- Add Bill ---
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

  // --- Save Daily Sales ---
  Future<void> _saveSales() async {
    final val = double.tryParse(_salesCtrl.text) ?? 0.0;
    final todaySale = widget.store.sales.firstWhere(
      (s) =>
          DateFormat('yyyy-MM-dd').format(s.date) ==
          DateFormat('yyyy-MM-dd').format(selectedDate),
      orElse: () => DailySales(id: '', date: selectedDate, totalSales: 0),
    );

    if (todaySale.id.isEmpty) {
      final s = DailySales(
        id: 's_${DateTime.now().millisecondsSinceEpoch}',
        date: selectedDate,
        totalSales: val,
      );
      await widget.store.addSales(s);
    } else {
      await widget.store.updateSales(todaySale.id, val);
    }
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Daily sales saved')));
  }

  // --- Delete Daily Sales ---
  Future<void> _deleteSales() async {
    final todaySale = widget.store.sales.firstWhere(
      (s) =>
          DateFormat('yyyy-MM-dd').format(s.date) ==
          DateFormat('yyyy-MM-dd').format(selectedDate),
      orElse: () => DailySales(id: '', date: selectedDate, totalSales: 0),
    );
    if (todaySale.id.isNotEmpty) {
      await widget.store.deleteSales(todaySale.id);
      _salesCtrl.text = '0';
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Daily sales deleted')));
    }
  }
}

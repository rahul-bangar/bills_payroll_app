import 'package:flutter/material.dart';
import '../data/datastore.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';

class WeeklyBillsPage extends StatefulWidget {
  final DataStore store;
  const WeeklyBillsPage({Key? key, required this.store}) : super(key: key);

  @override
  State<WeeklyBillsPage> createState() => _WeeklyBillsPageState();
}

class _WeeklyBillsPageState extends State<WeeklyBillsPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  final _billValueCtrl = TextEditingController();

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
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _billValueCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Value'),
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
          Text('Weekly bills', style: Theme.of(context).textTheme.titleMedium),
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
                      Text('Value: ₹${b.value.toStringAsFixed(2)}'),
                      Text('Date: ${DateFormat('yyyy-MM-dd').format(b.date)}'),
                    ],
                  ),
                  trailing: IconButton(
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
      isWeekly: true,
    );
    await widget.store.addBill(b);
    _billValueCtrl.clear();
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Weekly bill added')));
  }
}

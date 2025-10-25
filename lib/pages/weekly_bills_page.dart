// ---------------- lib/pages/weekly_bills_page.dart ----------------
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
  String selectedCategory = '';
  final _billValueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.store.categories.first;
  }

  @override
  Widget build(BuildContext context) {
    final billsForWeek = widget.store.bills.where((b) => b.isWeekly && _sameWeek(b.date, selectedDate)).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text('Week of: '), TextButton(onPressed: _pickDate, child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)))]),
        SizedBox(height: 8),
        Text('Add Weekly Bill', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(children: [
          Expanded(child: DropdownButton<String>(isExpanded: true, value: selectedCategory, items: widget.store.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => selectedCategory = v ?? widget.store.categories.first))),
          SizedBox(width: 8),
          SizedBox(width: 120, child: TextField(controller: _billValueCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Value'))),
          IconButton(onPressed: _addBill, icon: Icon(Icons.add_box)),
        ]),
        SizedBox(height: 12),
        Text('Bills for week', style: TextStyle(fontWeight: FontWeight.bold)),
        ...billsForWeek.map((b) => ListTile(title: Text('${b.category} - ${b.value}'), trailing: IconButton(icon: Icon(Icons.delete), onPressed: () async { await widget.store.deleteBill(b.id); setState(() {}); }))),
      ]),
    );
  }

  bool _sameWeek(DateTime a, DateTime b) => _weekStart(a) == _weekStart(b);
  DateTime _weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => selectedDate = d);
  }

  Future<void> _addBill() async {
    final val = double.tryParse(_billValueCtrl.text);
    if (val == null) return;
    final b = Bill(id: 'b_${DateTime.now().millisecondsSinceEpoch}', date: selectedDate, category: selectedCategory, value: val, isWeekly: true);
    await widget.store.addBill(b);
    _billValueCtrl.clear();
    setState(() {});
  }
}

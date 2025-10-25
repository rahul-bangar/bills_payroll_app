// ---------------- lib/pages/daily_bills_page.dart ----------------
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
  String selectedCategory = '';
  final _billValueCtrl = TextEditingController();
  final _salesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.store.categories.first;
    final todaySale = widget.store.sales.firstWhere(
        (s) => DateFormat('yyyy-MM-dd').format(s.date) == DateFormat('yyyy-MM-dd').format(selectedDate),
        orElse: () => DailySales(id: '', date: selectedDate, totalSales: 0));
    _salesCtrl.text = todaySale.totalSales.toString();
  }

  @override
  Widget build(BuildContext context) {
    final billsForDate = widget.store.bills.where((b) => DateFormat('yyyy-MM-dd').format(b.date) == DateFormat('yyyy-MM-dd').format(selectedDate) && !b.isWeekly).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text('Date: '), TextButton(onPressed: _pickDate, child: Text(DateFormat('yyyy-MM-dd').format(selectedDate))) ]),
          SizedBox(height: 8),
          Text('Add Bill', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            Expanded(child: DropdownButton<String>(isExpanded: true, value: selectedCategory, items: widget.store.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => selectedCategory = v ?? widget.store.categories.first))),
            SizedBox(width: 8),
            SizedBox(width: 120, child: TextField(controller: _billValueCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Value'))),
            IconButton(onPressed: _addBill, icon: Icon(Icons.add_box)),
          ]),
          SizedBox(height: 12),
          Text('Daily Sales', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            Expanded(child: TextField(controller: _salesCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Total sales'))),
            IconButton(onPressed: _saveSales, icon: Icon(Icons.save)),
          ]),
          SizedBox(height: 12),
          Text('Bills for the day', style: TextStyle(fontWeight: FontWeight.bold)),
          ...billsForDate.map((b) => ListTile(title: Text('${b.category} - ${b.value}'), subtitle: Text(b.id), trailing: IconButton(icon: Icon(Icons.delete), onPressed: () async { await widget.store.deleteBill(b.id); setState(() {});}))),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => selectedDate = d);
  }

  Future<void> _addBill() async {
    final val = double.tryParse(_billValueCtrl.text);
    if (val == null) return;
    final b = Bill(id: 'b_${DateTime.now().millisecondsSinceEpoch}', date: selectedDate, category: selectedCategory, value: val, isWeekly: false);
    await widget.store.addBill(b);
    _billValueCtrl.clear();
    setState(() {});
  }

  Future<void> _saveSales() async {
    final val = double.tryParse(_salesCtrl.text) ?? 0.0;
    final s = DailySales(id: 's_${DateTime.now().millisecondsSinceEpoch}', date: selectedDate, totalSales: val);
    await widget.store.addSales(s);
    setState(() {});
  }
}

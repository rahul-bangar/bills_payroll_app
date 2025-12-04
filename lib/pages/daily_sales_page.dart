import 'package:flutter/material.dart';
import '../data/datastore.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

class DailySalesPage extends StatefulWidget {
  final DataStore store;
  const DailySalesPage({Key? key, required this.store}) : super(key: key);

  @override
  State<DailySalesPage> createState() => _DailySalesPageState();
}

class _DailySalesPageState extends State<DailySalesPage> {
  DateTime selectedDate = DateTime.now();
  String _salesType = 'Counter';
  String _paymentMethod = 'Cash';
  
  final _cashValueCtrl = TextEditingController();
  final _bankValueCtrl = TextEditingController();
  final _chequeNumberCtrl = TextEditingController();
  final _posValueCtrl = TextEditingController();
  final _otherValueCtrl = TextEditingController();
  final _otherDescCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final salesForDate = widget.store.sales
        .where((s) => DateFormat('yyyy-MM-dd').format(s.date) ==
                     DateFormat('yyyy-MM-dd').format(selectedDate))
        .toList();

    final totalSales = salesForDate.fold(0.0, (sum, s) => sum + s.totalSales);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          // Date Picker
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
          const SizedBox(height: 12),

          // Add Sales Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Sales Entry',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    value: _salesType,
                    items: ['Counter', 'POS', 'Other']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _salesType = value!),
                    decoration: const InputDecoration(
                      labelText: 'Sales Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_salesType == 'Counter') ..._buildCounterFields(),
                  if (_salesType == 'POS') ..._buildPOSFields(),
                  if (_salesType == 'Other') ..._buildOtherFields(),
                  
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addSalesEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Entry'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Total Sales Summary
          Card(
            color: Colors.green.shade50,
            child: ListTile(
              title: const Text(
                'Total Sales for Day',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹${totalSales.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sales Entries List
          Text(
            'Sales Entries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          ...salesForDate.map((s) {
            return Card(
              child: ListTile(
                title: Text('${s.salesType} - ${s.paymentMethod ?? ''}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: ₹${s.totalSales.toStringAsFixed(2)}'),
                    if (s.chequeNumber != null) Text('Cheque: ${s.chequeNumber}'),
                    if (s.description != null) Text('Desc: ${s.description}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSalesEntry(s.id),
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

  List<Widget> _buildCounterFields() {
    return [
      DropdownButtonFormField<String>(
        value: _paymentMethod,
        items: ['Cash', 'Bank']
            .map((method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                ))
            .toList(),
        onChanged: (value) => setState(() => _paymentMethod = value!),
        decoration: const InputDecoration(
          labelText: 'Payment Method',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      if (_paymentMethod == 'Cash')
        TextField(
          controller: _cashValueCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cash Value',
            border: OutlineInputBorder(),
          ),
        ),
      if (_paymentMethod == 'Bank') ...[
        TextField(
          controller: _bankValueCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Bank Value',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chequeNumberCtrl,
          decoration: const InputDecoration(
            labelText: 'Cheque Number',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildPOSFields() {
    return [
      TextField(
        controller: _posValueCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'POS Value',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

  List<Widget> _buildOtherFields() {
    return [
      TextField(
        controller: _otherValueCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Value',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _otherDescCtrl,
        decoration: const InputDecoration(
          labelText: 'Description',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

  Future<void> _addSalesEntry() async {
    double value = 0.0;
    String? chequeNumber;
    String? description;

    switch (_salesType) {
      case 'Counter':
        if (_paymentMethod == 'Cash') {
          value = double.tryParse(_cashValueCtrl.text) ?? 0.0;
        } else {
          value = double.tryParse(_bankValueCtrl.text) ?? 0.0;
          chequeNumber = _chequeNumberCtrl.text.trim();
        }
        break;
      case 'POS':
        value = double.tryParse(_posValueCtrl.text) ?? 0.0;
        break;
      case 'Other':
        value = double.tryParse(_otherValueCtrl.text) ?? 0.0;
        description = _otherDescCtrl.text.trim();
        break;
    }

    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amount')),
      );
      return;
    }

    final sales = DailySales(
      id: 's_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      date: selectedDate,
      totalSales: value,
      salesType: _salesType,
      paymentMethod: _salesType == 'Counter' ? _paymentMethod : null,
      chequeNumber: chequeNumber,
      description: description,
    );

    await widget.store.addSales(sales);
    _clearFields();
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sales entry added')),
    );
  }

  void _showEditDialog(DailySales sales) {
    final valueCtrl = TextEditingController(text: sales.totalSales.toString());
    final chequeCtrl = TextEditingController(text: sales.chequeNumber ?? '');
    final descCtrl = TextEditingController(text: sales.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${sales.salesType} Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            if (sales.chequeNumber != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: chequeCtrl,
                decoration: const InputDecoration(labelText: 'Cheque Number'),
              ),
            ],
            if (sales.description != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateSalesEntry(
                sales.id,
                double.tryParse(valueCtrl.text) ?? sales.totalSales,
                sales.chequeNumber != null ? chequeCtrl.text : null,
                sales.description != null ? descCtrl.text : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSalesEntry(String id, double newAmount, String? chequeNumber, String? description) async {
    final index = widget.store.sales.indexWhere((s) => s.id == id);
    if (index != -1) {
      final oldSales = widget.store.sales[index];
      final updatedSales = DailySales(
        id: id,
        date: oldSales.date,
        totalSales: newAmount,
        salesType: oldSales.salesType,
        paymentMethod: oldSales.paymentMethod,
        chequeNumber: chequeNumber,
        description: description,
      );
      
      widget.store.sales[index] = updatedSales;
      await widget.store.saveSales();
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sales entry updated')),
      );
    }
  }

  Future<void> _deleteSalesEntry(String id) async {
    await widget.store.deleteSales(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sales entry deleted')),
    );
  }

  void _clearFields() {
    _cashValueCtrl.clear();
    _bankValueCtrl.clear();
    _chequeNumberCtrl.clear();
    _posValueCtrl.clear();
    _otherValueCtrl.clear();
    _otherDescCtrl.clear();
  }

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
}
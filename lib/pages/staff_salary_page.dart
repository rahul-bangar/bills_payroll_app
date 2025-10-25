import 'package:flutter/material.dart';
import '../data/datastore.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';

class StaffSalaryPage extends StatefulWidget {
  final DataStore store;
  const StaffSalaryPage({Key? key, required this.store}) : super(key: key);

  @override
  State<StaffSalaryPage> createState() => _StaffSalaryPageState();
}

class _StaffSalaryPageState extends State<StaffSalaryPage> {
  DateTime selectedDate = DateTime.now();
  final _nameCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _attendanceCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();

  StaffMember? _editing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          // --- Date Row ---
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

          // --- Add/Edit Staff Form ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editing == null ? 'Add Staff' : 'Edit Staff',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Staff Name
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Staff Name'),
                  ),
                  const SizedBox(height: 8),

                  // Monthly Salary
                  TextField(
                    controller: _salaryCtrl,
                    decoration: const InputDecoration(labelText: 'Monthly Salary'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),

                  // Attendance
                  TextField(
                    controller: _attendanceCtrl,
                    decoration: const InputDecoration(labelText: 'Attendance (days)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),

                  // Advance Paid
                  TextField(
                    controller: _advanceCtrl,
                    decoration: const InputDecoration(labelText: 'Advance Paid (₹)'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),

                  // Buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _saveStaff,
                        child: Text(_editing == null ? 'Add' : 'Update'),
                      ),
                      const SizedBox(width: 12),
                      if (_editing != null)
                        OutlinedButton(
                          onPressed: _clearForm,
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --- Staff List Header ---
          Text('Staff List', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // --- Staff List ---
          ...widget.store.staff.map((s) {
            // Use staff date for month/year in payable calculation
            final payable = s.payable(s.date.month, s.date.year);
            final payPeriod = DateFormat('dd MMM yyyy').format(s.date);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Monthly Salary: ₹${s.monthlySalary.toStringAsFixed(2)}'),
                    Text('Attendance: ${s.attendance}'),
                    Text('Advance Paid: ₹${s.advancePaid.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    Text(
                      'Payroll Date: $payPeriod',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Net Payable: ₹$payable',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editStaff(s)),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            widget.store.staff.removeWhere((x) => x.id == s.id);
                            await widget.store.saveStaff();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Staff removed')),
                            );
                          },
                        ),
                      ],
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

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => selectedDate = d);
  }

  void _editStaff(StaffMember s) {
    _editing = s;
    _nameCtrl.text = s.name;
    _salaryCtrl.text = s.monthlySalary.toString();
    _attendanceCtrl.text = s.attendance.toString();
    _advanceCtrl.text = s.advancePaid.toStringAsFixed(2);
    selectedDate = s.date; // set selected date to staff date for editing
    setState(() {});
  }

  void _clearForm() {
    _editing = null;
    _nameCtrl.clear();
    _salaryCtrl.clear();
    _attendanceCtrl.clear();
    _advanceCtrl.clear();
    selectedDate = DateTime.now();
    setState(() {});
  }

  Future<void> _saveStaff() async {
    final name = _nameCtrl.text.trim();
    final salary = double.tryParse(_salaryCtrl.text) ?? 0;
    final attendance = int.tryParse(_attendanceCtrl.text) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0.0;

    if (name.isEmpty || salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid name and monthly salary')),
      );
      return;
    }

    if (_editing != null) {
      final s = StaffMember(
        id: _editing!.id,
        name: name,
        monthlySalary: salary,
        attendance: attendance,
        advancePaid: advance,
        date: selectedDate,
      );
      await widget.store.updateStaff(s);
      _clearForm();
    } else {
      final s = StaffMember(
        id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        monthlySalary: salary,
        attendance: attendance,
        advancePaid: advance,
        date: selectedDate,
      );
      await widget.store.addStaff(s);
      _clearForm();
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff saved')),
    );
  }
}

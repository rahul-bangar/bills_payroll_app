// ---------------- lib/pages/staff_salary_page.dart ----------------
import 'package:flutter/material.dart';
import '../data/datastore.dart';
import '../data/models.dart';

class StaffSalaryPage extends StatefulWidget {
  final DataStore store;
  const StaffSalaryPage({Key? key, required this.store}) : super(key: key);

  @override
  State<StaffSalaryPage> createState() => _StaffSalaryPageState();
}

class _StaffSalaryPageState extends State<StaffSalaryPage> {
  final _nameCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  int _attendance = 0;
  double _advance = 0;
  StaffMember? _editing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_editing == null ? 'Add Staff' : 'Edit Staff', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Staff Name')),
        TextField(controller: _salaryCtrl, decoration: InputDecoration(labelText: 'Monthly Salary'), keyboardType: TextInputType.number),
        Row(children: [
          Expanded(child: Text('Attendance: $_attendance')), 
          IconButton(onPressed: () => setState(() => _attendance++), icon: Icon(Icons.add)),
          IconButton(onPressed: () => setState(() => _attendance = (_attendance>0?_attendance-1:0)), icon: Icon(Icons.remove)),
        ]),
        Row(children: [
          Expanded(child: Text('Advance Paid: $_advance')), 
          IconButton(onPressed: () => setState(()=> _advance += 100), icon: Icon(Icons.add)),
          IconButton(onPressed: () => setState(()=> _advance = (_advance >= 100 ? _advance-100 : 0)), icon: Icon(Icons.remove)),
        ]),
        ElevatedButton(onPressed: _saveStaff, child: Text(_editing == null ? 'Add' : 'Update')),
        SizedBox(height: 12),
        Text('Staff List', style: TextStyle(fontWeight: FontWeight.bold)),
        ...widget.store.staff.map((s) {
          final salary = s.payable(DateTime.now().month, DateTime.now().year);
          return ListTile(
            title: Text('${s.name} - Salary: ${salary.toStringAsFixed(2)}'),
            subtitle: Text('Attendance: ${s.attendance}, Advance: ${s.advancePaid}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(Icons.edit), onPressed: () => _editStaff(s)),
              IconButton(icon: Icon(Icons.delete), onPressed: () async { widget.store.staff.removeWhere((x)=>x.id==s.id); await widget.store.saveStaff(); setState((){}); }),
            ]),
          );
        }).toList(),
      ]),
    );
  }

  void _editStaff(StaffMember s) {
    _editing = s;
    _nameCtrl.text = s.name;
    _salaryCtrl.text = s.monthlySalary.toString();
    _attendance = s.attendance;
    _advance = s.advancePaid;
    setState((){});
  }

  Future<void> _saveStaff() async {
    final name = _nameCtrl.text;
    final salary = double.tryParse(_salaryCtrl.text) ?? 0;
    if (name.isEmpty || salary <= 0) return;
    if (_editing != null) {
      final s = StaffMember(id: _editing!.id, name: name, monthlySalary: salary, attendance: _attendance, advancePaid: _advance);
      await widget.store.updateStaff(s);
      _editing = null;
    } else {
      final s = StaffMember(id: 'staff_${DateTime.now().millisecondsSinceEpoch}', name: name, monthlySalary: salary, attendance: _attendance, advancePaid: _advance);
      await widget.store.addStaff(s);
    }
    _nameCtrl.clear();
    _salaryCtrl.clear();
    _attendance = 0;
    _advance = 0;
    setState((){});
  }
}

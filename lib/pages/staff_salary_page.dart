import 'package:flutter/material.dart';
import '../data/datastore.dart';
import '../data/models.dart';
import 'package:intl/intl.dart';

class StaffSalaryPage extends StatefulWidget {
  final DataStore store;
  final String restaurantName;
  const StaffSalaryPage({Key? key, required this.store, required this.restaurantName}) : super(key: key);

  @override
  State<StaffSalaryPage> createState() => _StaffSalaryPageState();
}

class _StaffSalaryPageState extends State<StaffSalaryPage> {
  DateTime selectedDate = DateTime.now();
  final _attendanceCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  String? selectedStaffId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          // --- Four Action Buttons ---
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddStaffDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Staff'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showEditStaffDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Staff'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showDeleteStaffDialog,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Staff'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showViewStaffDialog,
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Staff'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 12),

          // --- Add Salary Entry ---
          if (widget.store.staffDetails.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Salary Entry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStaffId,
                      items: widget.store.staffDetails
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.name} - ₹${s.monthlySalary}'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => selectedStaffId = value),
                      decoration: const InputDecoration(
                        labelText: 'Select Staff',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _attendanceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Attendance (days)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _advanceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Advance Paid',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _addSalaryEntry,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Entry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Paid Salaries Summary
          Card(
            color: Colors.green.shade50,
            child: ListTile(
              title: const Text(
                'Paid Salaries',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹${widget.store.staff.where((s) => s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Unpaid Salaries Summary
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              title: const Text(
                'Unpaid Salaries',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹${widget.store.staff.where((s) => !s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Salary Entries List ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Salary Entries', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export PDF',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.store.staff.map((s) {
            final payable = s.payable(s.date.month, s.date.year);
            return Card(
              child: ListTile(
                title: Text(s.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Salary: ₹${s.monthlySalary} | Attendance: ${s.attendance} days'),
                    Text('Advance: ₹${s.advancePaid} | Payable: ₹$payable'),
                    Text('Date: ${DateFormat('dd MMM yyyy').format(s.date)} | Status: ${s.isPaid ? "Paid" : "Unpaid"}'),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle_paid',
                      child: Text(s.isPaid ? 'Mark Unpaid' : 'Mark Paid'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') _editSalaryEntry(s);
                    if (value == 'toggle_paid') _togglePaidStatus(s);
                    if (value == 'delete') _deleteSalaryEntry(s.id);
                  },
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

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Staff Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: salaryCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Salary'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final salary = double.tryParse(salaryCtrl.text) ?? 0;
              if (name.isNotEmpty && salary > 0) {
                if (widget.store.staffDetails.any((s) => s.name.toLowerCase() == name.toLowerCase())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Staff with this name already exists')),
                  );
                  return;
                }
                final staff = StaffDetails(
                  id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  monthlySalary: salary,
                  createdDate: DateTime.now(),
                );
                await widget.store.addStaffDetails(staff);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Staff added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditStaffDialog() {
    if (widget.store.staffDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff to edit')),
      );
      return;
    }

    String? selectedId;
    final nameCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Staff Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedId,
                items: widget.store.staffDetails
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  final staff = widget.store.staffDetails.firstWhere((s) => s.id == value);
                  nameCtrl.text = staff.name;
                  salaryCtrl.text = staff.monthlySalary.toString();
                  setDialogState(() => selectedId = value);
                },
                decoration: const InputDecoration(labelText: 'Select Staff'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Staff Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly Salary'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedId != null) {
                  final name = nameCtrl.text.trim();
                  final salary = double.tryParse(salaryCtrl.text) ?? 0;
                  if (name.isNotEmpty && salary > 0) {
                    if (widget.store.staffDetails.any((s) => s.id != selectedId && s.name.toLowerCase() == name.toLowerCase())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Staff with this name already exists')),
                      );
                      return;
                    }
                    final oldStaff = widget.store.staffDetails.firstWhere((s) => s.id == selectedId);
                    final updatedStaff = StaffDetails(
                      id: selectedId!,
                      name: name,
                      monthlySalary: salary,
                      createdDate: oldStaff.createdDate,
                      isEdited: true,
                    );
                    await widget.store.updateStaffDetails(updatedStaff);
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Staff updated')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteStaffDialog() {
    if (widget.store.staffDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff to delete')),
      );
      return;
    }

    String? selectedId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete Staff Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedId,
                items: widget.store.staffDetails
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (value) => setDialogState(() => selectedId = value),
                decoration: const InputDecoration(labelText: 'Select Staff to Delete'),
              ),
              const SizedBox(height: 12),
              const Text('Note: This will not affect existing salary entries.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedId != null) {
                  await widget.store.deleteStaffDetails(selectedId!);
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Staff deleted')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewStaffDialog() {
    if (widget.store.staffDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff details available')),
      );
      return;
    }

    String? selectedId;
    StaffDetails? selectedStaff;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('View Staff Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedId,
                items: widget.store.staffDetails
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedStaff = widget.store.staffDetails.firstWhere((s) => s.id == value);
                  setDialogState(() => selectedId = value);
                },
                decoration: const InputDecoration(labelText: 'Select Staff'),
              ),
              if (selectedStaff != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: ${selectedStaff!.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Monthly Salary: ₹${selectedStaff!.monthlySalary.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        Text('Added: ${DateFormat('dd MMM yyyy').format(selectedStaff!.createdDate)}'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSalaryEntry() async {
    if (selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member')),
      );
      return;
    }

    final attendance = int.tryParse(_attendanceCtrl.text) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0.0;
    final staffDetails = widget.store.staffDetails.firstWhere((s) => s.id == selectedStaffId);

    // Check if salary already exists for this staff in the same month (unless staff details were edited)
    final existingEntry = widget.store.staff.where((s) => 
      s.name == staffDetails.name && 
      s.date.month == selectedDate.month && 
      s.date.year == selectedDate.year
    ).toList();
    
    if (existingEntry.isNotEmpty && !staffDetails.isEdited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salary already exists for this staff in this month. Please update existing entries.')),
      );
      return;
    }

    // Check if total attendance exceeds days in month
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final totalAttendance = existingEntry.fold(0, (sum, entry) => sum + entry.attendance) + attendance;
    if (totalAttendance > daysInMonth) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total attendance cannot exceed $daysInMonth days for this month')),
      );
      return;
    }

    final salaryEntry = StaffMember(
      id: 'salary_${DateTime.now().millisecondsSinceEpoch}',
      name: staffDetails.name,
      monthlySalary: staffDetails.monthlySalary,
      attendance: attendance,
      advancePaid: advance,
      date: selectedDate,
    );

    await widget.store.addStaff(salaryEntry);
    
    // Reset isEdited flag after salary entry is added
    if (staffDetails.isEdited) {
      final resetStaff = StaffDetails(
        id: staffDetails.id,
        name: staffDetails.name,
        monthlySalary: staffDetails.monthlySalary,
        createdDate: staffDetails.createdDate,
        isEdited: false,
      );
      await widget.store.updateStaffDetails(resetStaff);
    }
    
    _attendanceCtrl.clear();
    _advanceCtrl.clear();
    selectedStaffId = null;
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Salary entry added')),
    );
  }

  void _editSalaryEntry(StaffMember staff) {
    final attendanceCtrl = TextEditingController(text: staff.attendance.toString());
    final advanceCtrl = TextEditingController(text: staff.advancePaid.toString());
    DateTime selectedDate = staff.date;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Salary - ${staff.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: attendanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Attendance (days)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: advanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Advance Paid'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}'),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setDialogState(() => selectedDate = d);
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final attendance = int.tryParse(attendanceCtrl.text) ?? 0;
                final advance = double.tryParse(advanceCtrl.text) ?? 0.0;
                
                // Check if total attendance exceeds days in month
                final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
                final otherEntries = widget.store.staff.where((s) => 
                  s.name == staff.name && 
                  s.id != staff.id &&
                  s.date.month == selectedDate.month && 
                  s.date.year == selectedDate.year
                ).toList();
                final totalAttendance = otherEntries.fold(0, (sum, entry) => sum + entry.attendance) + attendance;
                if (totalAttendance > daysInMonth) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Total attendance cannot exceed $daysInMonth days for this month')),
                  );
                  return;
                }
                
                final updatedStaff = StaffMember(
                  id: staff.id,
                  name: staff.name,
                  monthlySalary: staff.monthlySalary,
                  attendance: attendance,
                  advancePaid: advance,
                  date: selectedDate,
                );
                
                await widget.store.updateStaff(updatedStaff);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salary entry updated')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSalaryEntry(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Salary Entry'),
        content: const Text('Are you sure you want to delete this salary entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.store.deleteStaff(id);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Salary entry deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _togglePaidStatus(StaffMember staff) async {
    final updatedStaff = StaffMember(
      id: staff.id,
      name: staff.name,
      monthlySalary: staff.monthlySalary,
      attendance: staff.attendance,
      advancePaid: staff.advancePaid,
      date: staff.date,
      isPaid: !staff.isPaid,
    );
    
    await widget.store.updateStaff(updatedStaff);
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salary marked as ${updatedStaff.isPaid ? "paid" : "unpaid"}')),
    );
  }

  Future<void> _exportPdf() async {
    try {
      final path = await widget.store.exportStaffSalaryPdf(selectedDate, widget.restaurantName);
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
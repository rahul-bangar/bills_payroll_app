import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';

class DataStore {
  final String restaurantId;
  final SharedPreferences prefs;
  List<Bill> bills = [];
  List<DailySales> sales = [];
  List<StaffMember> staff = [];
  List<StaffDetails> staffDetails = [];
  List<String> categories = [
    'Electricity',
    'Groceries',
    'Rent',
    'Internet',
    'Supplies',
    'Misc',
  ];

  DataStore._(this.prefs, this.restaurantId);

  static Future<DataStore> instanceInit({required String restaurantId}) async {
    final prefs = await SharedPreferences.getInstance();
    final ds = DataStore._(prefs, restaurantId);
    await ds._loadAll();
    return ds;
  }

  Future<void> _loadAll() async {
    String? load(String key) => prefs.getString('${key}_$restaurantId');

    final billsStr = load('bills_v1');
    if (billsStr != null) {
      bills = (jsonDecode(billsStr) as List)
          .map((e) => Bill.fromJson(e))
          .toList();
    }

    final salesStr = load('sales_v1');
    if (salesStr != null) {
      try {
        sales = (jsonDecode(salesStr) as List)
            .map((e) => DailySales.fromJson(e))
            .toList();
      } catch (e) {
        sales = [];
        await prefs.remove('sales_v1_$restaurantId');
      }
    }

    final staffStr = load('staff_v1');
    if (staffStr != null) {
      staff = (jsonDecode(staffStr) as List)
          .map((e) => StaffMember.fromJson(e))
          .toList();
    }

    final catStr = load('categories_v1');
    if (catStr != null) categories = List<String>.from(jsonDecode(catStr));
    
    final staffDetailsStr = load('staff_details_v1');
    if (staffDetailsStr != null) {
      staffDetails = (jsonDecode(staffDetailsStr) as List)
          .map((e) => StaffDetails.fromJson(e))
          .toList();
    }
  }

  Future<void> saveBills() async => prefs.setString(
        'bills_v1_$restaurantId',
        jsonEncode(bills.map((b) => b.toJson()).toList()),
      );

  Future<void> saveSales() async => prefs.setString(
        'sales_v1_$restaurantId',
        jsonEncode(sales.map((s) => s.toJson()).toList()),
      );

  Future<void> saveStaff() async => prefs.setString(
        'staff_v1_$restaurantId',
        jsonEncode(staff.map((s) => s.toJson()).toList()),
      );

  Future<void> saveCategories() async =>
      prefs.setString('categories_v1_$restaurantId', jsonEncode(categories));

  Future<void> saveStaffDetails() async => prefs.setString(
        'staff_details_v1_$restaurantId',
        jsonEncode(staffDetails.map((s) => s.toJson()).toList()),
      );

  // --- Bills ---
  Future<void> addBill(Bill b) async {
    bills.add(b);
    await saveBills();
  }

  Future<void> updateBill(Bill updatedBill) async {
    final index = bills.indexWhere((b) => b.id == updatedBill.id);
    if (index != -1) {
      bills[index] = updatedBill;
      await saveBills();
    }
  }

  Future<void> deleteBill(String id) async {
    bills.removeWhere((b) => b.id == id);
    await saveBills();
  }

  // --- Sales ---
  Future<void> addSales(DailySales s) async {
    sales.add(s);
    await saveSales();
  }

  Future<void> updateSales(String id, double totalSales) async {
    final index = sales.indexWhere((s) => s.id == id);
    if (index != -1) {
      sales[index] = DailySales(
        id: id,
        date: sales[index].date,
        totalSales: totalSales,
      );
      await saveSales();
    }
  }

  Future<void> deleteSales(String id) async {
    sales.removeWhere((s) => s.id == id);
    await saveSales();
  }

  // --- Staff ---
  Future<void> addStaff(StaffMember s) async {
    staff.add(s);
    await saveStaff();
  }

  Future<void> updateStaff(StaffMember s) async {
    staff = staff.map((x) => x.id == s.id ? s : x).toList();
    await saveStaff();
  }

  Future<void> deleteStaff(String id) async {
    staff.removeWhere((s) => s.id == id);
    await saveStaff();
  }

  // --- Staff Details ---
  Future<void> addStaffDetails(StaffDetails s) async {
    staffDetails.add(s);
    await saveStaffDetails();
  }

  Future<void> updateStaffDetails(StaffDetails s) async {
    staffDetails = staffDetails.map((x) => x.id == s.id ? s : x).toList();
    await saveStaffDetails();
  }

  Future<void> deleteStaffDetails(String id) async {
    staffDetails.removeWhere((s) => s.id == id);
    await saveStaffDetails();
  }

  // --- Summaries ---
  double totalSalesBetween(DateTime f, DateTime t) => sales
      .where((s) => !s.date.isBefore(f) && !s.date.isAfter(t))
      .fold(0.0, (p, e) => p + e.totalSales);

  double totalExpensesBetween(DateTime f, DateTime t) => bills
      .where((b) => !b.date.isBefore(f) && !b.date.isAfter(t))
      .fold(0.0, (p, e) => p + e.value);

  // --- PDF Export ---
  Future<String> exportDailyBillsPdf(DateTime date, String restaurantName) async {
    final pdf = pw.Document();
    
    final billsForDate = bills
        .where((b) => DateFormat('yyyy-MM-dd').format(b.date) == 
                     DateFormat('yyyy-MM-dd').format(date) && !b.isWeekly)
        .toList();
    
    final paidBills = billsForDate.where((b) => b.isPaid).fold(0.0, (sum, b) => sum + b.value);
    final unpaidBills = billsForDate.where((b) => !b.isPaid).fold(0.0, (sum, b) => sum + b.value);
    
    final categoryTotals = <String, double>{};
    for (final bill in billsForDate) {
      categoryTotals[bill.category] = (categoryTotals[bill.category] ?? 0) + bill.value;
    }
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            pw.Text('Daily Bills Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Restaurant: $restaurantName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(date)}', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Paid Bills', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${paidBills.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Unpaid Bills', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${unpaidBills.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ];

          if (billsForDate.isNotEmpty) {
            widgets.addAll([
              pw.Text('Bills Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...billsForDate.map((bill) => pw.TableRow(
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(bill.category)),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Rs.${bill.value.toStringAsFixed(2)}')),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(bill.isPaid ? 'Paid' : 'Pending')),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
            ]);
          }

          if (categoryTotals.isNotEmpty) {
            final maxValue = categoryTotals.values.reduce((a, b) => a > b ? a : b);
            widgets.addAll([
              pw.Text('Bills by Category', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...categoryTotals.entries.map((entry) {
                final percentage = entry.value / maxValue;
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(entry.key, style: pw.TextStyle(fontSize: 12)),
                          pw.Text('Rs.${entry.value.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 300 * percentage,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ]);
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets,
          );
        },
      ),
    );
    
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory();
    } else {
      downloadsDir = await getDownloadsDirectory();
    }
    
    if (downloadsDir == null) {
      throw Exception('Cannot determine downloads directory on this platform');
    }
    
    final file = File('${downloadsDir.path}/${restaurantName.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(date)}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  // --- Weekly Bills PDF Export ---
  Future<String> exportWeeklyBillsPdf(DateTime weekStart, String restaurantName) async {
    final pdf = pw.Document();
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    final billsForWeek = bills.where((b) => b.isWeekly).toList();
    
    final paidBills = billsForWeek.where((b) => b.isPaid).fold(0.0, (sum, b) => sum + b.value);
    final unpaidBills = billsForWeek.where((b) => !b.isPaid).fold(0.0, (sum, b) => sum + b.value);
    
    final categoryTotals = <String, double>{};
    for (final bill in billsForWeek) {
      categoryTotals[bill.category] = (categoryTotals[bill.category] ?? 0) + bill.value;
    }
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            pw.Text('Weekly Bills Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Restaurant: $restaurantName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Week: ${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Paid Bills', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${paidBills.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Unpaid Bills', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${unpaidBills.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ];

          if (billsForWeek.isNotEmpty) {
            widgets.addAll([
              pw.Text('Bills Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...billsForWeek.map((bill) => pw.TableRow(
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd MMM').format(bill.date))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(bill.category)),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Rs.${bill.value.toStringAsFixed(2)}')),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(bill.isPaid ? 'Paid' : 'Pending')),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
            ]);
          }

          if (categoryTotals.isNotEmpty) {
            final maxValue = categoryTotals.values.reduce((a, b) => a > b ? a : b);
            widgets.addAll([
              pw.Text('Bills by Category', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...categoryTotals.entries.map((entry) {
                final percentage = entry.value / maxValue;
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(entry.key, style: pw.TextStyle(fontSize: 12)),
                          pw.Text('Rs.${entry.value.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 300 * percentage,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ]);
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets,
          );
        },
      ),
    );
    
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory();
    } else {
      downloadsDir = await getDownloadsDirectory();
    }
    
    if (downloadsDir == null) {
      throw Exception('Cannot determine downloads directory on this platform');
    }
    
    final file = File('${downloadsDir.path}/${restaurantName.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(weekStart)}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  // --- Staff Salary PDF Export ---
  Future<String> exportStaffSalaryPdf(DateTime month, String restaurantName) async {
    final pdf = pw.Document();
    
    final staffForMonth = staff
        .where((s) => s.date.year == month.year && s.date.month == month.month)
        .toList();
    
    final paidSalaries = staffForMonth.where((s) => s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);
    final unpaidSalaries = staffForMonth.where((s) => !s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);
    final totalAdvance = staffForMonth.fold(0.0, (sum, s) => sum + s.advancePaid);
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            pw.Text('Staff Salary Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Restaurant: $restaurantName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Month: ${DateFormat('MMMM yyyy').format(month)}', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Advance Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${totalAdvance.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Unpaid Salary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${unpaidSalaries.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Total Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${paidSalaries.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ];

          if (staffForMonth.isNotEmpty) {
            widgets.addAll([
              pw.Text('Staff Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Attendance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Monthly Salary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Advance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Payable', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...staffForMonth.map((staff) {
                    final payable = staff.payable(staff.date.month, staff.date.year);
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(staff.name)),
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('${staff.attendance}')),
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Rs.${staff.monthlySalary.toStringAsFixed(2)}')),
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Rs.${staff.advancePaid.toStringAsFixed(2)}')),
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Rs.${payable.toStringAsFixed(2)}')),
                        pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(staff.isPaid ? 'Paid' : 'Pending')),
                      ],
                    );
                  }),
                ],
              ),
            ]);
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets,
          );
        },
      ),
    );
    
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory();
    } else {
      downloadsDir = await getDownloadsDirectory();
    }
    
    if (downloadsDir == null) {
      throw Exception('Cannot determine downloads directory on this platform');
    }
    
    final file = File('${downloadsDir.path}/${restaurantName.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(month)}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  // --- Dashboard PDF Export ---
  Future<String> exportDashboardPdf(String viewType, DateTime startDate, DateTime? endDate, String restaurantName) async {
    final pdf = pw.Document();
    
    List<Bill> filteredBills;
    List<DailySales> filteredSales;
    List<StaffMember> filteredStaff;
    String dateRange;
    
    switch (viewType) {
      case 'Daily':
        filteredBills = bills.where((b) => DateFormat('yyyy-MM-dd').format(b.date) == DateFormat('yyyy-MM-dd').format(startDate) && !b.isWeekly).toList();
        filteredSales = sales.where((s) => DateFormat('yyyy-MM-dd').format(s.date) == DateFormat('yyyy-MM-dd').format(startDate)).toList();
        filteredStaff = staff.where((s) => DateFormat('yyyy-MM-dd').format(s.date) == DateFormat('yyyy-MM-dd').format(startDate)).toList();
        dateRange = DateFormat('dd MMM yyyy').format(startDate);
        break;
      case 'Weekly':
        final weekEnd = startDate.add(const Duration(days: 6));
        filteredBills = bills.where((b) => !b.date.isBefore(startDate) && !b.date.isAfter(weekEnd)).toList();
        filteredSales = sales.where((s) => !s.date.isBefore(startDate) && !s.date.isAfter(weekEnd)).toList();
        filteredStaff = staff.where((s) => !s.date.isBefore(startDate) && !s.date.isAfter(weekEnd)).toList();
        dateRange = '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
        break;
      case 'Monthly':
        filteredBills = bills.where((b) => b.date.year == startDate.year && b.date.month == startDate.month).toList();
        filteredSales = sales.where((s) => s.date.year == startDate.year && s.date.month == startDate.month).toList();
        filteredStaff = staff.where((s) => s.date.year == startDate.year && s.date.month == startDate.month).toList();
        dateRange = DateFormat('MMMM yyyy').format(startDate);
        break;
      case 'Overall':
      default:
        final end = endDate ?? DateTime.now();
        filteredBills = bills.where((b) => !b.date.isBefore(startDate) && !b.date.isAfter(end)).toList();
        filteredSales = sales.where((s) => !s.date.isBefore(startDate) && !s.date.isAfter(end)).toList();
        filteredStaff = staff.where((s) => !s.date.isBefore(startDate) && !s.date.isAfter(end)).toList();
        dateRange = '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(end)}';
        break;
    }
    
    final totalSales = filteredSales.fold(0.0, (sum, s) => sum + s.totalSales);
    final paidExpenses = filteredBills.where((b) => b.isPaid).fold(0.0, (sum, b) => sum + b.value);
    final unpaidExpenses = filteredBills.where((b) => !b.isPaid).fold(0.0, (sum, b) => sum + b.value);
    final paidSalaries = filteredStaff.where((s) => s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);
    final unpaidSalaries = filteredStaff.where((s) => !s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);
    final totalAdvance = filteredStaff.fold(0.0, (sum, s) => sum + s.advancePaid);
    final profitOrLoss = totalSales - paidExpenses - paidSalaries;
    
    final categoryTotals = <String, double>{};
    for (final bill in filteredBills) {
      categoryTotals[bill.category] = (categoryTotals[bill.category] ?? 0) + bill.value;
    }
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            pw.Text('Dashboard Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Restaurant: $restaurantName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Period: $dateRange', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            
            // Sales Overview
            pw.Text('Sales Overview', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Sales', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs.${totalSales.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Expenses Overview
            pw.Text('Expenses Overview', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Paid Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${paidExpenses.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Pending Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${unpaidExpenses.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Salaries Overview
            pw.Text('Salaries Overview', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Advance Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${totalAdvance.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Unpaid Salary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${unpaidSalaries.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Total Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs.${paidSalaries.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Financial Summary
            pw.Text('Financial Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Profit / Loss', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs.${profitOrLoss.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ];

          if (categoryTotals.isNotEmpty) {
            final maxValue = categoryTotals.values.reduce((a, b) => a > b ? a : b);
            widgets.addAll([
              pw.Text('Expenses by Category', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...categoryTotals.entries.map((entry) {
                final percentage = entry.value / maxValue;
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(entry.key, style: pw.TextStyle(fontSize: 12)),
                          pw.Text('Rs.${entry.value.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 300 * percentage,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.orange,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ]);
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets,
          );
        },
      ),
    );
    
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory();
    } else {
      downloadsDir = await getDownloadsDirectory();
    }
    
    if (downloadsDir == null) {
      throw Exception('Cannot determine downloads directory on this platform');
    }
    
    final epochTime = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${restaurantName.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(startDate)}_$epochTime.pdf';
    
    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  // --- CSV Export ---
  Future<String> exportCsv({DateTime? from, DateTime? to}) async {
    final f = from ?? DateTime.now().subtract(const Duration(days: 365));
    final t = to ?? DateTime.now();

    final buffer = StringBuffer();
    buffer.writeln('Type,Date,Category,Value,Status,Items');

    for (final s in sales.where(
      (s) => !s.date.isBefore(f) && !s.date.isAfter(t),
    )) {
      buffer.writeln(
        'SALE,${DateFormat('yyyy-MM-dd').format(s.date)},,${s.totalSales},,',
      );
    }

    for (final b in bills.where(
      (b) => !b.date.isBefore(f) && !b.date.isAfter(t),
    )) {
      final itemsStr = b.items.map((i) => '${i.name}:${i.amount}').join('; ');
      buffer.writeln(
        'BILL,${DateFormat('yyyy-MM-dd').format(b.date)},${b.category},${b.value},${b.isPaid ? "Paid" : "Pending"},$itemsStr',
      );
    }

    buffer.writeln('');
    buffer.writeln('STAFF_PAYOUTS');
    buffer.writeln('Name,Month,Year,Attendance,MonthlySalary,Advance,Payable');

    final now = DateTime.now();
    for (final st in staff) {
      final payable = st.payable(now.month, now.year);
      buffer.writeln(
        '${st.name},${now.month},${now.year},${st.attendance},${st.monthlySalary},${st.advancePaid},${payable}',
      );
    }

    final csv = buffer.toString();

    Directory? downloadsDir;

    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory();
    } else {
      downloadsDir = await getDownloadsDirectory();
    }

    if (downloadsDir == null) {
      throw Exception('Cannot determine downloads directory on this platform');
    }

    final file = File(
      '${downloadsDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);

    return file.path;
  }
}
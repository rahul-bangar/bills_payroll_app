import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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
        // Clear old sales data that doesn't have new fields
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

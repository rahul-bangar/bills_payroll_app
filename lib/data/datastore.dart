// ---------------- lib/data/datastore.dart ----------------
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class DataStore {
  static const _billsKey = 'bills_v1';
  static const _salesKey = 'sales_v1';
  static const _staffKey = 'staff_v1';
  static const _categoriesKey = 'categories_v1';

  final SharedPreferences prefs;
  List<Bill> bills = [];
  List<DailySales> sales = [];
  List<StaffMember> staff = [];
  List<String> categories = ['Electricity', 'Groceries', 'Rent', 'Internet', 'Supplies', 'Misc'];

  DataStore._(this.prefs);

  static Future<DataStore> instanceInit() async {
    final prefs = await SharedPreferences.getInstance();
    final ds = DataStore._(prefs);
    await ds._loadAll();
    return ds;
  }

  Future<void> _loadAll() async {
    final load = (String key) => prefs.getString(key);
    final billsStr = load(_billsKey);
    if (billsStr != null) bills = (jsonDecode(billsStr) as List).map((e) => Bill.fromJson(e)).toList();
    final salesStr = load(_salesKey);
    if (salesStr != null) sales = (jsonDecode(salesStr) as List).map((e) => DailySales.fromJson(e)).toList();
    final staffStr = load(_staffKey);
    if (staffStr != null) staff = (jsonDecode(staffStr) as List).map((e) => StaffMember.fromJson(e)).toList();
    final catStr = load(_categoriesKey);
    if (catStr != null) categories = List<String>.from(jsonDecode(catStr));
  }

  Future<void> saveBills() async => prefs.setString(_billsKey, jsonEncode(bills.map((b) => b.toJson()).toList()));
  Future<void> saveSales() async => prefs.setString(_salesKey, jsonEncode(sales.map((s) => s.toJson()).toList()));
  Future<void> saveStaff() async => prefs.setString(_staffKey, jsonEncode(staff.map((s) => s.toJson()).toList()));
  Future<void> saveCategories() async => prefs.setString(_categoriesKey, jsonEncode(categories));

  Future<void> addBill(Bill b) async { bills.add(b); await saveBills(); }
  Future<void> deleteBill(String id) async { bills.removeWhere((b) => b.id == id); await saveBills(); }
  Future<void> addSales(DailySales s) async { sales.removeWhere((x) => DateFormat('yyyy-MM-dd').format(x.date) == DateFormat('yyyy-MM-dd').format(s.date)); sales.add(s); await saveSales(); }
  Future<void> addStaff(StaffMember s) async { staff.add(s); await saveStaff(); }
  Future<void> updateStaff(StaffMember s) async { staff = staff.map((x) => x.id == s.id ? s : x).toList(); await saveStaff(); }

  double totalSalesBetween(DateTime f, DateTime t) => sales.where((s) => !s.date.isBefore(f) && !s.date.isAfter(t)).fold(0.0, (p, e) => p + e.totalSales);
  double totalExpensesBetween(DateTime f, DateTime t) => bills.where((b) => !b.date.isBefore(f) && !b.date.isAfter(t)).fold(0.0, (p, e) => p + e.value);

  Future<String> exportCsv({DateTime? from, DateTime? to}) async {
    final f = from ?? DateTime.now().subtract(Duration(days: 365));
    final t = to ?? DateTime.now();
    final buf = StringBuffer('Type,Date,Category,Value\n');
    for (final s in sales.where((s) => !s.date.isBefore(f) && !s.date.isAfter(t))) buf.writeln('SALE,${DateFormat('yyyy-MM-dd').format(s.date)},,${s.totalSales}');
    for (final b in bills.where((b) => !b.date.isBefore(f) && !b.date.isAfter(t))) buf.writeln('BILL,${DateFormat('yyyy-MM-dd').format(b.date)},${b.category},${b.value}');
    final csv = buf.toString();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    return file.path;
  }
}
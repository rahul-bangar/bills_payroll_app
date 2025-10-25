// models.dart

// ------------------- Bill and BillItem -------------------

class Bill {
  String id;
  DateTime date;
  String category;
  double value;
  bool isWeekly;
  bool isPaid; // Track if the bill is paid
  List<BillItem> items; // Sub-items of the bill

  Bill({
    required this.id,
    required this.date,
    required this.category,
    required this.value,
    this.isWeekly = false,
    this.isPaid = false,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'category': category,
        'value': value,
        'isWeekly': isWeekly,
        'isPaid': isPaid,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        id: j['id'],
        date: DateTime.parse(j['date']),
        category: j['category'],
        value: (j['value'] as num).toDouble(),
        isWeekly: j['isWeekly'] ?? false,
        isPaid: j['isPaid'] ?? false,
        items: (j['items'] as List<dynamic>?)
                ?.map((i) => BillItem.fromJson(i))
                .toList() ??
            [],
      );
}

class BillItem {
  String name;
  double amount;

  BillItem({required this.name, required this.amount});

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
      };

  factory BillItem.fromJson(Map<String, dynamic> j) => BillItem(
        name: j['name'],
        amount: (j['amount'] as num).toDouble(),
      );
}

// ------------------- DailySales -------------------

class DailySales {
  String id;
  DateTime date;
  double totalSales;
  late String salesType;
  String? paymentMethod;
  String? chequeNumber;
  String? description;

  DailySales({
    required this.id,
    required this.date,
    required this.totalSales,
    String? salesType,
    this.paymentMethod,
    this.chequeNumber,
    this.description,
  }) {
    this.salesType = salesType ?? 'Counter';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalSales': totalSales,
        'salesType': salesType,
        'paymentMethod': paymentMethod,
        'chequeNumber': chequeNumber,
        'description': description,
      };

  factory DailySales.fromJson(Map<String, dynamic> j) => DailySales(
        id: j['id'],
        date: DateTime.parse(j['date']),
        totalSales: (j['totalSales'] as num).toDouble(),
        salesType: j['salesType'],
        paymentMethod: j['paymentMethod'],
        chequeNumber: j['chequeNumber'],
        description: j['description'],
      );
}

// ------------------- StaffDetails -------------------

class StaffDetails {
  String id;
  String name;
  double monthlySalary;
  DateTime createdDate;
  bool isEdited;

  StaffDetails({
    required this.id,
    required this.name,
    required this.monthlySalary,
    required this.createdDate,
    this.isEdited = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'monthlySalary': monthlySalary,
        'createdDate': createdDate.toIso8601String(),
        'isEdited': isEdited,
      };

  factory StaffDetails.fromJson(Map<String, dynamic> j) => StaffDetails(
        id: j['id'],
        name: j['name'],
        monthlySalary: (j['monthlySalary'] as num).toDouble(),
        createdDate: DateTime.parse(j['createdDate']),
        isEdited: (j['isEdited'] as bool?) ?? false,
      );
}

// ------------------- StaffMember -------------------

class StaffMember {
  String id;
  String name;
  double monthlySalary;
  int attendance; // days worked in the month
  double advancePaid;
  DateTime date;
  bool? _isPaid;

  StaffMember({
    required this.id,
    required this.name,
    required this.monthlySalary,
    this.attendance = 0,
    this.advancePaid = 0.0,
    required this.date,
    bool isPaid = false,
  }) : _isPaid = isPaid;

  bool get isPaid => _isPaid ?? false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'monthlySalary': monthlySalary,
        'attendance': attendance,
        'advancePaid': advancePaid,
        'date': date.toIso8601String(),
        'isPaid': isPaid,
      };

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
        id: j['id'],
        name: j['name'],
        monthlySalary: (j['monthlySalary'] as num).toDouble(),
        attendance: j['attendance'] ?? 0,
        advancePaid: (j['advancePaid'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.parse(j['date']),
        isPaid: (j['isPaid'] as bool?) ?? false,
      );

  int payable(int month, int year) => roundUpToNearest50(
        (attendance / daysInMonth(month, year)) * monthlySalary - advancePaid,
      );
}

// ------------------- Utility Functions -------------------

int roundUpToNearest50(double value) {
  return ((value / 50).ceil()) * 50;
}

int daysInMonth(int month, int year) {
  final nextMonth = (month == 12)
      ? DateTime(year + 1, 1, 1)
      : DateTime(year, month + 1, 1);
  return nextMonth.difference(DateTime(year, month, 1)).inDays;
}

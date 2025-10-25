// ---------------- lib/data/models.dart ----------------
class Bill {
  String id;
  DateTime date;
  String category;
  double value;
  bool isWeekly;

  Bill({required this.id, required this.date, required this.category, required this.value, this.isWeekly = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'category': category,
    'value': value,
    'isWeekly': isWeekly
  };

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
    id: j['id'],
    date: DateTime.parse(j['date']),
    category: j['category'],
    value: (j['value'] as num).toDouble(),
    isWeekly: j['isWeekly'] ?? false
  );
}

class DailySales {
  String id;
  DateTime date;
  double totalSales;

  DailySales({required this.id, required this.date, required this.totalSales});

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'totalSales': totalSales
  };

  factory DailySales.fromJson(Map<String, dynamic> j) => DailySales(
    id: j['id'],
    date: DateTime.parse(j['date']),
    totalSales: (j['totalSales'] as num).toDouble()
  );
}

class StaffMember {
  String id;
  String name;
  double monthlySalary;
  int attendance;
  double advancePaid;

  StaffMember({required this.id, required this.name, required this.monthlySalary, this.attendance = 0, this.advancePaid = 0.0});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'monthlySalary': monthlySalary,
    'attendance': attendance,
    'advancePaid': advancePaid
  };

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
    id: j['id'],
    name: j['name'],
    monthlySalary: (j['monthlySalary'] as num).toDouble(),
    attendance: j['attendance'] ?? 0,
    advancePaid: (j['advancePaid'] as num?)?.toDouble() ?? 0.0
  );

  double payable(int month, int year) => (attendance / daysInMonth(month, year)) * monthlySalary - advancePaid;
}

int daysInMonth(int month, int year) {
  final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return nextMonth.difference(DateTime(year, month, 1)).inDays;
}
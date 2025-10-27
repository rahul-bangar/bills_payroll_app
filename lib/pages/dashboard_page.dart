// ---------------- lib/pages/dashboard_page.dart ----------------
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/datastore.dart';

class DashboardPage extends StatefulWidget {
  final DataStore store;
  final String restaurantName;
  const DashboardPage({Key? key, required this.store, required this.restaurantName}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedView = 'Overall';
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  bool _showUnpaidDetails = false;
  bool _showWeeklyUnpaidDetails = false;
  bool _showDailyUnpaidDetails = false;
  bool _showUnpaidSalariesDetails = false;

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // --- Filter data based on selected view ---
    final sales = _getFilteredSales();
    final totalSales = sales.fold(0.0, (p, s) => p + s.totalSales);

    final bills = _getFilteredBills();

    final paidExpenses = bills.where((b) => b.isPaid).fold(0.0, (p, b) => p + b.value);
    final pendingExpenses = bills.where((b) => !b.isPaid).fold(0.0, (p, b) => p + b.value);

    // --- Staff salaries ---
    final staffList = _getFilteredStaff();
    final paidSalaries = staffList.where((s) => s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);
    final unpaidSalaries = staffList.where((s) => !s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);
    final totalSalary = paidSalaries + unpaidSalaries;

    final profitOrLoss = totalSales - paidExpenses - paidSalaries;

    // Check for unpaid bills from previous days (exclude weekly bills)
    final today = DateTime.now();
    final unpaidBillDates = widget.store.bills
        .where((b) => !b.isPaid && !b.isWeekly && b.date.isBefore(DateTime(today.year, today.month, today.day)))
        .map((b) => b.date)
        .toSet()
        .toList();
    unpaidBillDates.sort((a, b) => a.compareTo(b));

    // Check for unpaid weekly bills
    final unpaidWeeklyBills = widget.store.bills
        .where((b) => !b.isPaid && b.isWeekly)
        .toList();

    // Check for unpaid daily bills for today
    final unpaidDailyBills = widget.store.bills
        .where((b) => !b.isPaid && 
               !b.isWeekly && 
               DateFormat('yyyy-MM-dd').format(b.date) == 
               DateFormat('yyyy-MM-dd').format(today))
        .toList();

    // Check for all unpaid salaries
    final allUnpaidSalaries = widget.store.staff
        .where((s) => !s.isPaid)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Refresh the dashboard
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.dashboard,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Financial Overview',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

          // Unpaid Bills Warning Banner
          if (unpaidBillDates.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showUnpaidDetails = !_showUnpaidDetails),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unpaid Bills Alert!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                          Icon(
                            _showUnpaidDetails ? Icons.expand_less : Icons.expand_more,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showUnpaidDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: unpaidBillDates.map((date) {
                          final billsForDate = widget.store.bills
                              .where((b) => !b.isPaid && !b.isWeekly && 
                                     DateFormat('yyyy-MM-dd').format(b.date) == 
                                     DateFormat('yyyy-MM-dd').format(date))
                              .toList();
                          final totalUnpaid = billsForDate.fold(0.0, (sum, b) => sum + b.value);
                          
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(date)} - ₹${totalUnpaid.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...billsForDate.map((bill) => Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 2),
                                  child: Text('• ${bill.category}: ₹${bill.value.toStringAsFixed(2)}'),
                                )),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // Weekly Unpaid Bills Warning Banner
          if (unpaidWeeklyBills.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.orange.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showWeeklyUnpaidDetails = !_showWeeklyUnpaidDetails),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'WEEKLY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unpaid Weekly Bills!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                          Icon(
                            _showWeeklyUnpaidDetails ? Icons.expand_less : Icons.expand_more,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showWeeklyUnpaidDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: unpaidWeeklyBills.map((bill) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${bill.category}: ₹${bill.value.toStringAsFixed(2)} (Added: ${DateFormat('dd MMM yyyy').format(bill.date)})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // Daily Unpaid Bills Warning Banner
          if (unpaidDailyBills.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showDailyUnpaidDetails = !_showDailyUnpaidDetails),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.today, color: Colors.blue),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DAILY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unpaid Daily Bills for Today!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          Icon(
                            _showDailyUnpaidDetails ? Icons.expand_less : Icons.expand_more,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showDailyUnpaidDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: unpaidDailyBills.map((bill) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${bill.category}: ₹${bill.value.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // Unpaid Salaries Warning Banner
          if (allUnpaidSalaries.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade50, Colors.purple.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showUnpaidSalariesDetails = !_showUnpaidSalariesDetails),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.purple),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SALARY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unpaid Salaries Alert!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                          ),
                          Icon(
                            _showUnpaidSalariesDetails ? Icons.expand_less : Icons.expand_more,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showUnpaidSalariesDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: allUnpaidSalaries.map((staff) {
                          final payableAmount = staff.payable(staff.date.month, staff.date.year).toDouble() + staff.advancePaid;
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${staff.name}: ₹${payableAmount.toStringAsFixed(2)} (${DateFormat('MMM yyyy').format(staff.date)})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

          // --- View Selector ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time Period',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedView,
                          items: ['Overall', 'Monthly', 'Weekly', 'Daily']
                              .map((view) => DropdownMenuItem(
                                    value: view,
                                    child: Text(view),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedView = value!),
                          decoration: const InputDecoration(
                            labelText: 'View Period',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_selectedView != 'Overall')
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today, color: Colors.white),
                          tooltip: 'Change Date',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (_selectedView != 'Overall')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _getDateRangeText(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

          const SizedBox(height: 20),
          
          // Financial Overview Grid
          _buildFinancialGrid(totalSales, paidExpenses, pendingExpenses, profitOrLoss),
          
          const SizedBox(height: 20),
          // Salary Overview
          _buildSalaryOverview(staffList),
          
          const SizedBox(height: 20),
          _buildExpenseChart(bills),
          const SizedBox(height: 20),
          
          // Export Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text('Export PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialGrid(double totalSales, double paidExpenses, double pendingExpenses, double profitOrLoss) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                'Total Sales',
                '₹${totalSales.toStringAsFixed(2)}',
                Icons.trending_up,
                const Color(0xFF10B981),
                const Color(0xFFD1FAE5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialCard(
                'Profit/Loss',
                '₹${profitOrLoss.toStringAsFixed(2)}',
                profitOrLoss >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                profitOrLoss >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                profitOrLoss >= 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                'Paid Expenses',
                '₹${paidExpenses.toStringAsFixed(2)}',
                Icons.check_circle,
                const Color(0xFF6366F1),
                const Color(0xFFEDE9FE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialCard(
                'Pending Expenses',
                '₹${pendingExpenses.toStringAsFixed(2)}',
                Icons.pending,
                const Color(0xFFF59E0B),
                const Color(0xFFFEF3C7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialCard(String title, String amount, IconData icon, Color iconColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryOverview(List<dynamic> staffList) {
    final advancePaid = staffList.fold(0.0, (sum, s) => sum + s.advancePaid);
    final unpaidSalary = staffList.where((s) => !s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble());
    final totalSalaryPaid = staffList.where((s) => s.isPaid).fold(0.0, (sum, s) => sum + s.payable(s.date.month, s.date.year).toDouble() + s.advancePaid);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salary Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          _buildSalaryItem('Advance Paid', advancePaid, Icons.payment, const Color(0xFF8B5CF6)),
          const SizedBox(height: 12),
          _buildSalaryItem('Unpaid Salary', unpaidSalary, Icons.schedule, const Color(0xFFEF4444)),
          const SizedBox(height: 12),
          _buildSalaryItem('Total Salary Paid', totalSalaryPaid, Icons.check_circle, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildSalaryItem(String title, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<dynamic> _getFilteredSales() {
    switch (_selectedView) {
      case 'Daily':
        return widget.store.sales.where((s) => 
          DateFormat('yyyy-MM-dd').format(s.date) == 
          DateFormat('yyyy-MM-dd').format(_selectedDate)).toList();
      case 'Weekly':
        final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
        return widget.store.sales.where((s) => 
          !s.date.isBefore(_selectedWeekStart) && 
          !s.date.isAfter(weekEnd)).toList();
      case 'Monthly':
        return widget.store.sales.where((s) =>
          s.date.year == _selectedMonth.year &&
          s.date.month == _selectedMonth.month).toList();
      default:
        return widget.store.sales;
    }
  }

  List<dynamic> _getFilteredBills() {
    switch (_selectedView) {
      case 'Daily':
        return widget.store.bills.where((b) => 
          DateFormat('yyyy-MM-dd').format(b.date) == 
          DateFormat('yyyy-MM-dd').format(_selectedDate)).toList();
      case 'Weekly':
        final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
        return widget.store.bills.where((b) => 
          !b.date.isBefore(_selectedWeekStart) && 
          !b.date.isAfter(weekEnd)).toList();
      case 'Monthly':
        return widget.store.bills.where((b) =>
          b.date.year == _selectedMonth.year &&
          b.date.month == _selectedMonth.month).toList();
      default:
        return widget.store.bills;
    }
  }

  List<dynamic> _getFilteredStaff() {
    switch (_selectedView) {
      case 'Daily':
        return widget.store.staff.where((s) => 
          DateFormat('yyyy-MM-dd').format(s.date) == 
          DateFormat('yyyy-MM-dd').format(_selectedDate)).toList();
      case 'Weekly':
        final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
        return widget.store.staff.where((s) => 
          !s.date.isBefore(_selectedWeekStart) && 
          !s.date.isAfter(weekEnd)).toList();
      case 'Monthly':
        return widget.store.staff.where((s) =>
          s.date.year == _selectedMonth.year &&
          s.date.month == _selectedMonth.month).toList();
      default:
        return widget.store.staff;
    }
  }

  String _getDateRangeText() {
    switch (_selectedView) {
      case 'Daily':
        return 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}';
      case 'Weekly':
        final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
        return 'Week: ${DateFormat('MMM dd').format(_selectedWeekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
      case 'Monthly':
        return 'Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}';
      default:
        return '';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedView == 'Monthly' ? _selectedMonth : 
                   _selectedView == 'Weekly' ? _selectedWeekStart : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        switch (_selectedView) {
          case 'Daily':
            _selectedDate = picked;
            break;
          case 'Weekly':
            _selectedWeekStart = _getWeekStart(picked);
            break;
          case 'Monthly':
            _selectedMonth = DateTime(picked.year, picked.month, 1);
            break;
        }
      });
    }
  }

  Widget _buildExpenseChart(List<dynamic> bills) {
    if (bills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses to display',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final categoryTotals = <String, double>{};
    for (final bill in bills) {
      categoryTotals[bill.category] = (categoryTotals[bill.category] ?? 0) + bill.value;
    }

    if (categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses to display',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = categoryTotals.values.reduce((a, b) => a > b ? a : b);
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expenses by Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Text(
                      _getDateRangeText().isEmpty ? 'Overall' : _getDateRangeText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...categoryTotals.entries.toList().asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final percentage = entry.value / maxValue;
            final color = colors[index % colors.length];
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.grey.shade200,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    try {
      DateTime? startDate;
      DateTime? endDate;
      
      if (_selectedView == 'Overall') {
        // Ask user to select date range
        final result = await showDialog<Map<String, DateTime>>(
          context: context,
          builder: (context) => _DateRangeDialog(),
        );
        if (result == null) return;
        startDate = result['start']!;
        endDate = result['end']!;
      } else if (_selectedView == 'Daily') {
        // Ask user to select a day
        startDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (startDate == null) return;
      } else if (_selectedView == 'Weekly') {
        // Ask user to select a week
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: _selectedWeekStart,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selectedDate == null) return;
        startDate = _getWeekStart(selectedDate);
      } else if (_selectedView == 'Monthly') {
        // Ask user to select a month
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: _selectedMonth,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selectedDate == null) return;
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      }
      
      if (startDate == null) return;
      
      final path = await widget.store.exportDashboardPdf(_selectedView, startDate, endDate, widget.restaurantName);
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

class _DateRangeDialog extends StatefulWidget {
  @override
  _DateRangeDialogState createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Date Range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('From: ${DateFormat('dd MMM yyyy').format(_startDate)}'),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: _endDate,
                  );
                  if (date != null) setState(() => _startDate = date);
                },
                child: const Text('Change'),
              ),
            ],
          ),
          Row(
            children: [
              Text('To: ${DateFormat('dd MMM yyyy').format(_endDate)}'),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _endDate = date);
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
          onPressed: () => Navigator.pop(context, {'start': _startDate, 'end': _endDate}),
          child: const Text('Export'),
        ),
      ],
    );
  }
}

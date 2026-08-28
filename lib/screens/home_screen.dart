import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _customers = [];
  Map<String, double> _totals = {'له': 0.0, 'عليه': 0.0, 'الرصيد': 0.0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _db.getAllCustomers();
      final totals = await _db.getTotals();

      List<Map<String, dynamic>> customersWithBalance = [];
      for (var customerMap in customers) {
        final balance = await _db.getCustomerBalance(customerMap['id'] as int);
        customersWithBalance.add({
          ...customerMap,
          'balance': balance,
        });
      }

      setState(() {
        _customers = customersWithBalance;
        _totals = totals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('حدث خطأ أثناء تحميل البيانات');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _getBalanceColor(double balance) {
    if (balance > 0) return Colors.green.shade700;
    if (balance < 0) return Colors.red.shade700;
    return Colors.grey.shade700;
  }

  String _formatBalance(double balance) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    if (balance > 0) return 'له: ${formatter.format(balance)}';
    if (balance < 0) return 'عليه: ${formatter.format(balance.abs())}';
    return 'متعادل';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'حساباتي',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: _showBackupDialog,
            tooltip: 'الحفظ الاحتياطي',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? _buildEmptyState()
                    : _buildCustomersList(),
          ),
          _buildBottomBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('عميل جديد'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا يوجد عملاء',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر + لإضافة عميل جديد',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _customers.length,
        itemBuilder: (context, index) {
          final customer = _customers[index];
          final balance = customer['balance'] as double;
          final customerObj = Customer.fromMap(customer);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(customer: customerObj),
                  ),
                );
                _loadData();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _getBalanceColor(balance).withOpacity(0.15),
                      child: Text(
                        customer['name'].toString()[0],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _getBalanceColor(balance),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (customer['phone'] != null &&
                              customer['phone'].toString().isNotEmpty)
                            Text(
                              customer['phone'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatBalance(balance),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _getBalanceColor(balance),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تفاصيل >',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTotalItem(
                    'له (لنا)',
                    _totals['له'] ?? 0.0,
                    Colors.green.shade700,
                    formatter,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildTotalItem(
                    'عليه (لهم)',
                    _totals['عليه'] ?? 0.0,
                    Colors.red.shade700,
                    formatter,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildTotalItem(
                    'الرصيد',
                    _totals['الرصيد'] ?? 0.0,
                    (_totals['الرصيد'] ?? 0.0) >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    formatter,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(
      String label, double value, Color color, NumberFormat formatter) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showBackupDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'الحفظ الاحتياطي',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.save_alt, color: Colors.blue),
              ),
              title: const Text('حفظ نسخة احتياطية'),
              subtitle: const Text('حفظ قاعدة البيانات في الجهاز'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final path = await _db.backupDatabase();
                  _showError('تم الحفظ في: $path');
                } catch (e) {
                  _showError('فشل الحفظ الاحتياطي');
                }
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.share, color: Colors.green),
              ),
              title: const Text('مشاركة نسخة احتياطية'),
              subtitle: const Text('مشاركة قاعدة البيانات مع تطبيقات أخرى'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _db.exportBackup();
                } catch (e) {
                  _showError('فشل المشاركة');
                }
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: const Icon(Icons.restore, color: Colors.orange),
              ),
              title: const Text('استعادة نسخة احتياطية'),
              subtitle: const Text('استعادة قاعدة البيانات من ملف'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _db.restoreDatabase();
                  _loadData();
                  _showError('تمت الاستعادة بنجاح');
                } catch (e) {
                  _showError('فشلت الاستعادة');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import 'transaction_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _transactions = [];
  double _balance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions =
          await _db.getCustomerTransactions(widget.customer.id!);
      final balance = await _db.getCustomerBalance(widget.customer.id!);
      setState(() {
        _transactions = transactions;
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
    final formatter = NumberFormat('#,##0.00', 'ar');
    final dateFormatter = DateFormat('yyyy/MM/dd - HH:mm', 'ar');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDeleteCustomer,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _balance >= 0
                    ? [Colors.green.shade600, Colors.green.shade800]
                    : [Colors.red.shade600, Colors.red.shade800],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_balance >= 0 ? Colors.green : Colors.red)
                      .withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'الرصيد الحالي',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatBalance(_balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.customer.phone != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        widget.customer.phone!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addTransaction('عليه'),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('عليه'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addTransaction('له'),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('له'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل العمليات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_transactions.length} عملية',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد عمليات مسجلة',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final t = _transactions[index];
                          final isForHim = t['type'] == 'له';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isForHim
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                child: Icon(
                                  isForHim
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isForHim
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              title: Text(
                                '${t['type']}: ${formatter.format(t['amount'])}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isForHim
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dateFormatter
                                      .format(DateTime.parse(t['date']))),
                                  if (t['note'] != null &&
                                      t['note'].toString().isNotEmpty)
                                    Text(
                                      t['note'],
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.grey),
                                onPressed: () =>
                                    _confirmDeleteTransaction(t['id'] as int),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _addTransaction(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionScreen(customer: widget.customer),
      ),
    );
    if (result == true) _loadData();
  }

  void _confirmDeleteTransaction(int transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العملية'),
        content: const Text('هل أنت متأكد من حذف هذه العملية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _db.deleteTransaction(transactionId);
              _loadData();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العميل'),
        content: const Text(
            'هل أنت متأكد من حذف هذا العميل وجميع عملياته؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _db.deleteCustomer(widget.customer.id!);
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

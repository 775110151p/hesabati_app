import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'transaction_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
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
    final txs = await DatabaseHelper.instance.getCustomerTransactions(widget.customerId);
    final bal = await DatabaseHelper.instance.getCustomerBalance(widget.customerId);
    setState(() {
      _transactions = txs;
      _balance = bal;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await DatabaseHelper.instance.deleteCustomer(widget.customerId);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Text('صافي الحساب', style: TextStyle(fontSize: 16)),
                      Text(
                        '${_balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final isFor = tx['type'] == 'له';
                      return ListTile(
                        title: Text('${tx['amount']} ريال'),
                        subtitle: Text('${tx['note'] ?? ''}\n${tx['date']}'),
                        trailing: Text(
                          tx['type'],
                          style: TextStyle(
                            color: isFor ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionScreen(customerId: widget.customerId),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

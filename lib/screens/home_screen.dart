import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _customers = [];
  Map<String, double> _totals = {'له': 0.0, 'عليه': 0.0, 'الرصيد': 0.0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final customers = await DatabaseHelper.instance.getAllCustomers();
    final totals = await DatabaseHelper.instance.getTotals();
    setState(() {
      _customers = customers;
      _totals = totals;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حساباتي'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('لك', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            Text('${_totals['له']?.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('عليك', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            Text('${_totals['عليه']?.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _customers.isEmpty
                      ? const Center(child: Text('لا يوجد عملاء مضافون حالياً'))
                      : ListView.builder(
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(customer['name']),
                              subtitle: Text(customer['phone'] ?? 'بدون رقم'),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerDetailScreen(
                                      customerId: customer['id'],
                                      customerName: customer['name'],
                                    ),
                                  ),
                                );
                                _refreshData();
                              },
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
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
          _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

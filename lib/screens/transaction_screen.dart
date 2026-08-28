import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TransactionScreen extends StatefulWidget {
  final int customerId;

  const TransactionScreen({super.key, required this.customerId});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'له';

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    await DatabaseHelper.instance.insertTransaction({
      'customer_id': widget.customerId,
      'amount': amount,
      'type': _type,
      'note': _noteController.text,
      'date': DateTime.now().toString().split(' ').first,
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة معاملة جديدة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ'),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'ملاحظة'),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('له (لك)'),
                    value: 'له',
                    groupValue: _type,
                    onChanged: (val) => setState(() => _type = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('عليه'),
                    value: 'عليه',
                    groupValue: _type,
                    onChanged: (val) => setState(() => _type = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('حفظ المعاملة'),
            ),
          ],
        ),
      ),
    );
  }
}

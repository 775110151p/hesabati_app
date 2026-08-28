class Customer {
  final int? id;
  final String name;
  final String? phone;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class Transaction {
  final int? id;
  final int customerId;
  final double amount;
  final String type;
  final String? note;
  final DateTime date;

  Transaction({
    this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'type': type,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      amount: map['amount'] as double,
      type: map['type'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
    );
  }
}

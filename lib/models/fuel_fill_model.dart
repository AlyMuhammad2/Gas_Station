class FuelFillModel {
  final String fuelType;
  final String paymentMethod;
  final double price;
  final String invoiceNumber;
  final bool isPrinted;
  final int? nozzleId;
  final double amount;
  final double volume;
  final double totalizer;
  final double totalAfter;
  final DateTime transactionDate;
  final int? employeeId;
  final int? shiftDailyId;
  final String uId;
  final dynamic shiftDaily;
  final dynamic nozzle;
  final dynamic employee;
  final int? id;
  final DateTime createdAt;
  final dynamic updatedBy;
  final DateTime? updatedAt;
  final List<dynamic> domainEvents;

  FuelFillModel({
    required this.fuelType,
    required this.paymentMethod,
    required this.price,
    required this.invoiceNumber,
    required this.isPrinted,
    required this.nozzleId,
    required this.amount,
    required this.volume,
    required this.totalizer,
    required this.totalAfter,
    required this.transactionDate,
    required this.employeeId,
    this.shiftDailyId,
    required this.uId,
    this.shiftDaily,
    this.nozzle,
    this.employee,
    required this.id,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    required this.domainEvents,
  });

  factory FuelFillModel.fromJson(Map<String, dynamic> json) {
    return FuelFillModel(
      fuelType: json['fuelType'],
      paymentMethod: json['paymentMethod'],
      price: json['price'],
      invoiceNumber: json['invoiceNumber'],
      isPrinted: json['isPrinted'],
      nozzleId: json['nozzleId'],
      amount: json['amount'],
      volume: json['volume'],
      totalizer: json['totalizer'],
      totalAfter: json['totalAfter'],
      transactionDate: DateTime.parse(json['transactionDate']),
      employeeId: json['employeeId'],
      shiftDailyId: json['shiftDailyId'],
      uId: json['uId'],
      shiftDaily: json['shiftDaily'],
      nozzle: json['nozzle'],
      employee: json['employee'],
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedBy: json['updatedBy'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      domainEvents: List<dynamic>.from(json['domainEvents']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fuelType': fuelType,
      'paymentMethod': paymentMethod,
      'price': price,
      'invoiceNumber': invoiceNumber,
      'isPrinted': isPrinted,
      'nozzleId': nozzleId,
      'amount': amount,
      'volume': volume,
      'totalizer': totalizer,
      'totalAfter': totalAfter,
      'transactionDate': transactionDate.toIso8601String(),
      'employeeId': employeeId,
      'shiftDailyId': shiftDailyId,
      'uId': uId,
      'shiftDaily': shiftDaily,
      'nozzle': nozzle,
      'employee': employee,
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedAt': updatedAt?.toIso8601String(),
      'domainEvents': domainEvents,
    };
  }
}

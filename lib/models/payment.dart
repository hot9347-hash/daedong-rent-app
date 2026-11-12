class Payment {
  final int? id;
  final int roomId;
  final String yearMonth; // 'YYYY-MM'
  final int amountExpected;
  final int amountPaid;
  final String paymentStatus; // 미납, 완납, 부분입금
  final String paidDate;
  final String note;
  
  // 조인 정보
  final String? buildingName;
  final String? roomNumber;
  final String? tenantName;
  final String? tenantPhone;
  final int? payDay;

  Payment({
    this.id,
    required this.roomId,
    required this.yearMonth,
    required this.amountExpected,
    this.amountPaid = 0,
    this.paymentStatus = '미납',
    this.paidDate = '',
    this.note = '',
    this.buildingName,
    this.roomNumber,
    this.tenantName,
    this.tenantPhone,
    this.payDay,
  });

  int get unpaidAmount => (amountExpected - amountPaid).clamp(0, amountExpected);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'year_month': yearMonth,
      'amount_expected': amountExpected,
      'amount_paid': amountPaid,
      'payment_status': paymentStatus,
      'paid_date': paidDate,
      'note': note,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      roomId: map['room_id'],
      yearMonth: map['year_month'],
      amountExpected: map['amount_expected'] ?? 0,
      amountPaid: map['amount_paid'] ?? 0,
      paymentStatus: map['payment_status'] ?? '미납',
      paidDate: map['paid_date'] ?? '',
      note: map['note'] ?? '',
      buildingName: map['building_name'],
      roomNumber: map['room_number'],
      tenantName: map['tenant_name'],
      tenantPhone: map['tenant_phone'],
      payDay: map['pay_day'],
    );
  }
}

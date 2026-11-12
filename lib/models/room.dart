class Room {
  final int? id;
  final String buildingName;
  final String roomNumber;
  final String tenantName;
  final String tenantPhone;
  final String contractType; // 월세, 전세
  final int deposit; // 만원 단위
  final int monthlyRent; // 만원 단위
  final int maintenanceFee; // 만원 단위
  final int payDay; // 매월 납부일 (1~31)
  final String startDate;
  final String endDate;
  final String memo;
  final String status; // 계약중, 공실

  Room({
    this.id,
    required this.buildingName,
    required this.roomNumber,
    this.tenantName = '',
    this.tenantPhone = '',
    this.contractType = '월세',
    this.deposit = 0,
    this.monthlyRent = 0,
    this.maintenanceFee = 0,
    this.payDay = 5,
    this.startDate = '',
    this.endDate = '',
    this.memo = '',
    this.status = '계약중',
  });

  int get totalExpected => monthlyRent + maintenanceFee;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'building_name': buildingName,
      'room_number': roomNumber,
      'tenant_name': tenantName,
      'tenant_phone': tenantPhone,
      'contract_type': contractType,
      'deposit': deposit,
      'monthly_rent': monthlyRent,
      'maintenance_fee': maintenanceFee,
      'pay_day': payDay,
      'start_date': startDate,
      'end_date': endDate,
      'memo': memo,
      'status': status,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      buildingName: map['building_name'] ?? '대동주택',
      roomNumber: map['room_number'] ?? '',
      tenantName: map['tenant_name'] ?? '',
      tenantPhone: map['tenant_phone'] ?? '',
      contractType: map['contract_type'] ?? '월세',
      deposit: map['deposit'] ?? 0,
      monthlyRent: map['monthly_rent'] ?? 0,
      maintenanceFee: map['maintenance_fee'] ?? 0,
      payDay: map['pay_day'] ?? 5,
      startDate: map['start_date'] ?? '',
      endDate: map['end_date'] ?? '',
      memo: map['memo'] ?? '',
      status: map['status'] ?? '계약중',
    );
  }
}

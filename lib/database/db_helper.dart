import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../models/payment.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('daedong_rent.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. 호실 및 세입자 정보
    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        building_name TEXT NOT NULL,
        room_number TEXT NOT NULL,
        tenant_name TEXT,
        tenant_phone TEXT,
        contract_type TEXT DEFAULT '월세',
        deposit INTEGER DEFAULT 0,
        monthly_rent INTEGER DEFAULT 0,
        maintenance_fee INTEGER DEFAULT 0,
        pay_day INTEGER DEFAULT 5,
        start_date TEXT,
        end_date TEXT,
        memo TEXT,
        status TEXT DEFAULT '계약중'
      )
    ''');

    // 2. 월별 수납 및 선납 내역
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        year_month TEXT NOT NULL,
        amount_expected INTEGER NOT NULL,
        amount_paid INTEGER DEFAULT 0,
        payment_status TEXT DEFAULT '미납',
        paid_date TEXT,
        note TEXT,
        FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
        UNIQUE(room_id, year_month)
      )
    ''');

    // 3. 입금 문자(SMS) 수신 로그
    await db.execute('''
      CREATE TABLE sms_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sms_text TEXT,
        parsed_room TEXT,
        amount INTEGER,
        result_msg TEXT,
        received_at TEXT
      )
    ''');

    // 대동주택 16개 호실 (201~204, 301~304, 401~404, 501~504) 기본 시드 데이터 생성
    await _seedDaedongRooms(db);
  }

  Future<void> _seedDaedongRooms(Database db) async {
    final now = DateTime.now();
    final currentYm = DateFormat('yyyy-MM').format(now);
    final startDate = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 180)));
    final endDate = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 540)));

    final sampleTenants = [
      {'room': '201호', 'name': '김민수', 'phone': '010-1234-5678', 'rent': 45, 'fee': 5, 'day': 5},
      {'room': '202호', 'name': '이서연', 'phone': '010-2345-6789', 'rent': 45, 'fee': 5, 'day': 10},
      {'room': '203호', 'name': '박지훈', 'phone': '010-3456-7890', 'rent': 50, 'fee': 5, 'day': 15},
      {'room': '204호', 'name': '최유진', 'phone': '010-4567-8901', 'rent': 45, 'fee': 5, 'day': 25},

      {'room': '301호', 'name': '정태양', 'phone': '010-5678-9012', 'rent': 50, 'fee': 5, 'day': 5},
      {'room': '302호', 'name': '강다은', 'phone': '010-6789-0123', 'rent': 45, 'fee': 5, 'day': 10},
      {'room': '303호', 'name': '윤도현', 'phone': '010-7890-1234', 'rent': 55, 'fee': 5, 'day': 15},
      {'room': '304호', 'name': '', 'phone': '', 'rent': 50, 'fee': 5, 'day': 25, 'status': '공실'},

      {'room': '401호', 'name': '한지민', 'phone': '010-8901-2345', 'rent': 50, 'fee': 5, 'day': 5},
      {'room': '402호', 'name': '송준호', 'phone': '010-9012-3456', 'rent': 48, 'fee': 5, 'day': 10},
      {'room': '403호', 'name': '오세영', 'phone': '010-0123-4567', 'rent': 48, 'fee': 5, 'day': 15},
      {'room': '404호', 'name': '장현우', 'phone': '010-1122-3344', 'rent': 50, 'fee': 5, 'day': 25},

      {'room': '501호', 'name': '임채원', 'phone': '010-2233-4455', 'rent': 52, 'fee': 5, 'day': 5},
      {'room': '502호', 'name': '신재혁', 'phone': '010-3344-5566', 'rent': 52, 'fee': 5, 'day': 10},
      {'room': '503호', 'name': '안소희', 'phone': '010-4455-6677', 'rent': 50, 'fee': 5, 'day': 15},
      {'room': '504호', 'name': '배성민', 'phone': '010-5566-7788', 'rent': 50, 'fee': 5, 'day': 25},
    ];

    for (var t in sampleTenants) {
      final isVacant = t['status'] == '공실';
      final roomId = await db.insert('rooms', {
        'building_name': '대동주택',
        'room_number': t['room'],
        'tenant_name': isVacant ? '' : t['name'],
        'tenant_phone': isVacant ? '' : t['phone'],
        'contract_type': '월세',
        'deposit': isVacant ? 500 : 1000,
        'monthly_rent': t['rent'],
        'maintenance_fee': t['fee'],
        'pay_day': t['day'],
        'start_date': isVacant ? '' : startDate,
        'end_date': isVacant ? '' : endDate,
        'memo': isVacant ? '도배 완료, 입주 상담 가능' : '성실 입금 세대',
        'status': isVacant ? '공실' : '계약중',
      });

      // 계약중인 방에 대해 당월 청구 레코드 생성
      if (!isVacant) {
        final expected = ((t['rent'] as int?) ?? 0) + ((t['fee'] as int?) ?? 0);
        await db.insert('payments', {
          'room_id': roomId,
          'year_month': currentYm,
          'amount_expected': expected,
          'amount_paid': 0,
          'payment_status': '미납',
          'note': '당월 정기 청구',
        });
      }
    }
  }

  // --- 호실 목록 조회 ---
  Future<List<Room>> getAllRooms() async {
    final db = await database;
    final res = await db.query('rooms', orderBy: 'room_number ASC');
    return res.map((e) => Room.fromMap(e)).toList();
  }

  // --- 호실 정보 수정 (이름, 연락처, 보증금, 월세, 관리비, 납부일, 상태 등) ---
  Future<void> updateRoom(Room room) async {
    final db = await database;
    await db.update(
      'rooms',
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
    );

    final currentYm = DateFormat('yyyy-MM').format(DateTime.now());
    if (room.status == '공실') {
      // 공실로 변경된 경우 당월 미납 청구 내역이 있으면 제거
      await db.delete(
        'payments',
        where: "room_id = ? AND year_month = ? AND payment_status = '미납'",
        whereArgs: [room.id, currentYm],
      );
    } else {
      // 계약중인 경우 당월 청구 예정액(월세+관리비) 동기화
      final newExpected = room.totalExpected;
      await syncMonthlyPayments(currentYm);
      await db.rawUpdate('''
        UPDATE payments
        SET amount_expected = ?,
            payment_status = CASE
              WHEN amount_paid >= ? AND ? > 0 THEN '완납'
              WHEN amount_paid > 0 THEN '부분입금'
              ELSE '미납'
            END
        WHERE room_id = ? AND year_month = ?
      ''', [newExpected, newExpected, newExpected, room.id, currentYm]);
    }
  }

  // --- 수납 내역 직접 수정 (입금액, 상태 초기화 등) ---
  Future<void> updatePaymentDirect({
    required int paymentId,
    required int amountExpected,
    required int amountPaid,
    required String note,
  }) async {
    final db = await database;
    String status = '미납';
    if (amountPaid >= amountExpected && amountExpected > 0) {
      status = '완납';
    } else if (amountPaid > 0) {
      status = '부분입금';
    }
    final paidDate = amountPaid > 0 ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : '';
    await db.update(
      'payments',
      {
        'amount_expected': amountExpected,
        'amount_paid': amountPaid,
        'payment_status': status,
        'paid_date': paidDate,
        'note': note,
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  // --- 특정 년월의 수납 현황 조회 (호실 정보 조인) ---
  Future<List<Payment>> getPaymentsForMonth(String yearMonth) async {
    final db = await database;
    // 당월 청구 데이터가 없는 계약중 호실 동기화
    await syncMonthlyPayments(yearMonth);

    final res = await db.rawQuery('''
      SELECT p.*, r.building_name, r.room_number, r.tenant_name, r.tenant_phone, r.pay_day
      FROM payments p
      JOIN rooms r ON p.room_id = r.id
      WHERE p.year_month = ?
      ORDER BY r.room_number ASC
    ''', [yearMonth]);

    return res.map((e) => Payment.fromMap(e)).toList();
  }

  Future<void> syncMonthlyPayments(String yearMonth) async {
    final db = await database;
    final rooms = await db.query('rooms', where: "status = '계약중'");
    for (var r in rooms) {
      final expected = ((r['monthly_rent'] as int?) ?? 0) + ((r['maintenance_fee'] as int?) ?? 0);
      await db.rawInsert('''
        INSERT OR IGNORE INTO payments (room_id, year_month, amount_expected, amount_paid, payment_status, note)
        VALUES (?, ?, ?, 0, '미납', '정기 청구')
      ''', [r['id'], yearMonth, expected]);
    }
  }

  // 다음 달 YYYY-MM 계산 ('2026-11' -> '2026-12')
  String _getNextYm(String ym) {
    final parts = ym.split('-');
    int y = int.parse(parts[0]);
    int m = int.parse(parts[1]);
    if (m == 12) {
      return '${y + 1}-01';
    } else {
      return '$y-${(m + 1).toString().padLeft(2, '0')}';
    }
  }

  // --- 핵심: 2달치 이상 초과 입금 시 당월 완납 + 익월 선납 자동 처리 ---
  Future<Map<String, dynamic>> processIncomingPayment({
    required int roomId,
    required int totalAmount, // 만원 단위
    required String paidDate,
    String note = '자동 입금',
  }) async {
    final db = await database;
    
    // 호실 정보
    final roomRows = await db.query('rooms', where: 'id = ?', whereArgs: [roomId]);
    if (roomRows.isEmpty) {
      return {'success': false, 'msg': '호실 정보를 찾을 수 없습니다.'};
    }
    final room = Room.fromMap(roomRows.first);
    final monthlyExpected = room.totalExpected;
    if (monthlyExpected <= 0) {
      return {'success': false, 'msg': '호실 월 청구금액이 0원입니다.'};
    }

    final currentYm = DateFormat('yyyy-MM').format(DateTime.now());
    await syncMonthlyPayments(currentYm);

    // 1. 미납 상태인 가장 이른 월부터 조회
    final unpaidRows = await db.query(
      'payments',
      where: "room_id = ? AND payment_status != '완납'",
      orderBy: 'year_month ASC',
      whereArgs: [roomId],
    );

    int remaining = totalAmount;
    List<String> details = [];

    // 기존 미납 건 먼저 순차 충당
    for (var row in unpaidRows) {
      if (remaining <= 0) break;
      final expected = row['amount_expected'] as int;
      final currentPaid = row['amount_paid'] as int;
      final needed = expected - currentPaid;
      if (needed <= 0) continue;

      final payThis = remaining >= needed ? needed : remaining;
      final newPaid = currentPaid + payThis;
      remaining -= payThis;

      final newStatus = newPaid >= expected ? '완납' : '부분입금';
      await db.update(
        'payments',
        {
          'amount_paid': newPaid,
          'payment_status': newStatus,
          'paid_date': paidDate,
          'note': '$note ($newStatus)',
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      details.add("${row['year_month']}월: ${payThis}만원 ($newStatus)");
    }

    // 기존 미납을 다 채우고도 잔액이 남았다면 -> 다음 달(익월) 선납 생성!
    String lastYm = currentYm;
    final maxRow = await db.rawQuery('SELECT MAX(year_month) as max_ym FROM payments WHERE room_id = ?', [roomId]);
    if (maxRow.isNotEmpty && maxRow.first['max_ym'] != null) {
      lastYm = maxRow.first['max_ym'] as String;
    }

    while (remaining > 0) {
      final targetYm = _getNextYm(lastYm);
      lastYm = targetYm;

      final payThis = remaining >= monthlyExpected ? monthlyExpected : remaining;
      remaining -= payThis;
      final newStatus = payThis >= monthlyExpected ? '완납' : '부분입금';

      await db.rawInsert('''
        INSERT INTO payments (room_id, year_month, amount_expected, amount_paid, payment_status, paid_date, note)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(room_id, year_month) DO UPDATE SET
          amount_paid = amount_paid + excluded.amount_paid,
          payment_status = excluded.payment_status,
          paid_date = excluded.paid_date,
          note = excluded.note
      ''', [roomId, targetYm, monthlyExpected, payThis, newStatus, paidDate, '$note (선납 $newStatus)']);

      details.add("$targetYm월(선납): ${payThis}만원 ($newStatus)");
    }

    return {
      'success': true,
      'room': '${room.buildingName} ${room.roomNumber} (${room.tenantName})',
      'amount': totalAmount,
      'details': details,
    };
  }

  // --- SMS 로그 기록 및 조회 ---
  Future<void> logSms(String text, String? room, int amount, String result) async {
    final db = await database;
    await db.insert('sms_logs', {
      'sms_text': text,
      'parsed_room': room ?? '미상',
      'amount': amount,
      'result_msg': result,
      'received_at': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    });
  }

  Future<List<Map<String, dynamic>>> getSmsLogs({int limit = 20}) async {
    final db = await database;
    return await db.query('sms_logs', orderBy: 'id DESC', limit: limit);
  }
}

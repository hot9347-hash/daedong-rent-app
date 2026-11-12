import 'dart:async';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/room.dart';

class SmsService {
  static final SmsService instance = SmsService._init();

  SmsService._init();

  Future<void> init() async {
    // 무권한 클린 모드 초기화
  }

  // --- 핵심: 입금 문자/알림 분석 및 대동주택 호실 자동 매칭 ---
  Future<Map<String, dynamic>> processRawSms(String smsText) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. 입금 금액 파싱
    int amountManwon = 0;
    final wonRegex = RegExp(r'([0-9,]{4,})\s*원?');
    final match = wonRegex.firstMatch(smsText);

    if (match != null) {
      final raw = int.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0;
      amountManwon = raw ~/ 10000;
    } else {
      final manwonRegex = RegExp(r'([0-9]+)\s*만\s*원?');
      final manMatch = manwonRegex.firstMatch(smsText);
      if (manMatch != null) {
        amountManwon = int.tryParse(manMatch.group(1)!) ?? 0;
      }
    }

    if (amountManwon <= 0) {
      await DbHelper.instance.logSms(smsText, null, 0, '실패: 입금 금액 추출 불가');
      return {'success': false, 'msg': '금액을 추출할 수 없습니다.'};
    }

    // 2. 대동주택 16개 호실 및 세입자명 매칭
    final rooms = await DbHelper.instance.getAllRooms();
    Room? matchedRoom;

    for (var r in rooms) {
      final name = r.tenantName.trim();
      final roomNo = r.roomNumber.trim();
      final roomDigits = roomNo.replaceAll(RegExp(r'[^0-9]'), '');

      if (name.isNotEmpty && name.length >= 2 && smsText.contains(name)) {
        matchedRoom = r;
        break;
      }
      if (roomNo.isNotEmpty && smsText.contains(roomNo)) {
        matchedRoom = r;
        break;
      }
      if (roomDigits.length >= 3 && smsText.contains(roomDigits)) {
        matchedRoom = r;
        break;
      }
    }

    if (matchedRoom == null) {
      await DbHelper.instance.logSms(smsText, null, amountManwon, '실패: 일치하는 호실 없음');
      return {'success': false, 'msg': '일치하는 호실이나 세입자를 찾지 못했습니다.'};
    }

    // 3. 2달치 이상 선납 처리
    final result = await DbHelper.instance.processIncomingPayment(
      roomId: matchedRoom.id!,
      totalAmount: amountManwon,
      paidDate: todayStr,
      note: '자동 입금 반영',
    );

    if (result['success'] == true) {
      final details = (result['details'] as List<String>).join(' / ');
      await DbHelper.instance.logSms(
        smsText,
        '${matchedRoom.roomNumber} (${matchedRoom.tenantName})',
        amountManwon,
        '성공: $details',
      );
    }

    return result;
  }
}

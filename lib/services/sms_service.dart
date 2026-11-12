import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/room.dart';

// 백그라운드에서 SMS가 도착했을 때 안드로이드 OS가 호출하는 최상위 핸들러
@pragma('vm:entry-point')
void backGroundMessageHandler(SmsMessage message) async {
  final text = message.body ?? '';
  if (text.contains('입금')) {
    await SmsService.instance.processRawSms(text);
  }
}

class SmsService {
  static final SmsService instance = SmsService._init();
  final Telephony _telephony = Telephony.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  SmsService._init();

  // 초기화 및 안드로이드 권한/리스너 등록
  Future<void> init() async {
    // 1. 로컬 푸시 알림 초기화
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    // 2. 안드로이드 SMS 권한 확인 및 리스너 등록
    final bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == true) {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          final text = message.body ?? '';
          if (text.contains('입금')) {
            await processRawSms(text);
          }
        },
        onBackgroundMessage: backGroundMessageHandler,
      );
    }
  }

  // 상단 푸시 알림 표시
  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'rent_payment_channel',
      '월세 입금 알림',
      channelDescription: '대동주택 입금 문자 자동 감지 및 완납/선납 알림',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  // --- 핵심: 입금 문자 분석 및 대동주택 호실 자동 매칭 ---
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
      // '100만원' 형태 검사
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

      // 1순위: 세입자 이름이 문자에 포함된 경우 (예: "김민수")
      if (name.isNotEmpty && name.length >= 2 && smsText.contains(name)) {
        matchedRoom = r;
        break;
      }
      // 2순위: 호수가 문자에 포함된 경우 (예: "201호", "201")
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
      note: 'SMS 자동 입금',
    );

    if (result['success'] == true) {
      final details = (result['details'] as List<String>).join(' / ');
      await DbHelper.instance.logSms(
        smsText,
        '${matchedRoom.roomNumber} (${matchedRoom.tenantName})',
        amountManwon,
        '성공: $details',
      );

      // 상단 팝업 알림 띄우기
      await _showNotification(
        '🍂 [대동주택 ${matchedRoom.roomNumber}] ${amountManwon}만원 입금 완료',
        details,
      );
    }

    return result;
  }
}

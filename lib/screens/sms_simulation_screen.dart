import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../database/db_helper.dart';
import '../theme/autumn_theme.dart';

class SmsSimulationScreen extends StatefulWidget {
  const SmsSimulationScreen({super.key});

  @override
  State<SmsSimulationScreen> createState() => _SmsSimulationScreenState();
}

class _SmsSimulationScreenState extends State<SmsSimulationScreen> {
  final TextEditingController _smsController = TextEditingController(
    text: '[KB국민은행] 11/12 14:10 201호 김민수 입금 1,000,000원 잔액 5,200,000원',
  );

  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final list = await DbHelper.instance.getSmsLogs();
    setState(() => _logs = list);
  }

  Future<void> _simulateSms(String text) async {
    setState(() => _isLoading = true);
    final result = await SmsService.instance.processRawSms(text);
    await _loadLogs();
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: AutumnTheme.accentForest),
                SizedBox(width: 8),
                Text('자동 입금 처리 완료'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('대상: ${result['room']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('입금액: ${result['amount']}만원'),
                const Divider(),
                const Text('상세 반영 내역:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...((result['details'] as List<String>).map((d) => Text('• $d'))),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인', style: TextStyle(color: AutumnTheme.primaryMaple)),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['msg'] ?? '처리 실패'),
            backgroundColor: AutumnTheme.accentWine,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('입금 문자 자동 감지 & 테스트'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 가상 테스트 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.sms, color: AutumnTheme.primaryMaple),
                      SizedBox(width: 8),
                      Text(
                        '가상 입금 문자 테스트 (시뮬레이터)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AutumnTheme.textEspresso),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '실제 은행 문자가 도착했을 때와 동일하게 2달치 선납 충당 로직을 즉시 시험해 볼 수 있습니다.',
                    style: TextStyle(fontSize: 13, color: AutumnTheme.textMuted),
                  ),
                  const SizedBox(height: 14),

                  // 빠른 샘플 선택 버튼들
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('201호 100만(2달치)', '[KB] 11/12 201호 김민수 입금 1,000,000원'),
                        const SizedBox(width: 8),
                        _buildPresetChip('301호 55만(당월완납)', '[신한] 11/12 301호 정태양 입금 550,000원'),
                        const SizedBox(width: 8),
                        _buildPresetChip('401호 110만(2달치)', '[우리] 11/12 401호 한지민 1,100,000원 입금'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _smsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AutumnTheme.backgroundCozy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AutumnTheme.secondaryAmber.withOpacity(0.3)),
                      ),
                      hintText: '은행 입금 문자 내용을 입력하세요',
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('입금 문자 분석 및 자동 반영 실행'),
                      onPressed: _isLoading ? null : () => _simulateSms(_smsController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 수신 로그
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📜 최근 자동 감지 기록',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AutumnTheme.textEspresso),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: AutumnTheme.primaryMaple),
                onPressed: _loadLogs,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_logs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('아직 수신/처리된 문자 기록이 없습니다.', style: TextStyle(color: AutumnTheme.textMuted)),
                ),
              ),
            )
          else
            ..._logs.map((log) => _buildLogCard(log)),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String text) {
    return ActionChip(
      backgroundColor: AutumnTheme.secondaryAmber.withOpacity(0.12),
      label: Text(label, style: const TextStyle(fontSize: 12, color: AutumnTheme.primaryMaple, fontWeight: FontWeight.bold)),
      onPressed: () {
        setState(() => _smsController.text = text);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final isSuccess = (log['result_msg'] as String? ?? '').contains('성공');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  log['parsed_room'] ?? '미상',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AutumnTheme.textEspresso),
                ),
                Text(
                  log['received_at'] ?? '',
                  style: const TextStyle(fontSize: 11, color: AutumnTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              log['result_msg'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: isSuccess ? AutumnTheme.accentForest : AutumnTheme.accentWine,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

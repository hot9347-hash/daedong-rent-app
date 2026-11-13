import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/payment.dart';
import '../theme/autumn_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _currentYm = DateFormat('yyyy-MM').format(DateTime.now());
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await DbHelper.instance.getPaymentsForMonth(_currentYm);
    setState(() {
      _payments = list;
      _isLoading = false;
    });
  }

  Future<void> _copyPhoneNumber(String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('연락처 복사 완료: $phoneNumber'),
          backgroundColor: AutumnTheme.primaryMaple,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalExpected = _payments.fold<int>(0, (sum, p) => sum + p.amountExpected);
    final totalPaid = _payments.fold<int>(0, (sum, p) => sum + p.amountPaid);
    final totalUnpaid = (totalExpected - totalPaid).clamp(0, totalExpected);
    final rate = totalExpected > 0 ? (totalPaid / totalExpected * 100) : 0.0;

    final unpaidList = _payments.where((p) => p.paymentStatus != '완납').toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('🍁 ', style: TextStyle(fontSize: 22)),
            Text(
              '대동주택',
              style: TextStyle(
                fontFamily: 'Jua',
                fontSize: 24,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                color: AutumnTheme.textEspresso,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AutumnTheme.primaryMaple),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AutumnTheme.primaryMaple))
          : RefreshIndicator(
              color: AutumnTheme.primaryMaple,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA04218), Color(0xFFD67D27)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AutumnTheme.primaryMaple.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '대동주택 (201호~504호 / 총 16세대)',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_currentYm월',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '풍요로운 가을, 이달의 수납 현황',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem('청구 예정', '$totalExpected만원'),
                            _buildStatItem('수납 완료', '$totalPaid만원'),
                            _buildStatItem('미납액', '$totalUnpaid만원', isHighlight: totalUnpaid > 0),
                            _buildStatItem('수납률', '${rate.toStringAsFixed(1)}%'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AutumnTheme.accentWine, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '미납 및 납부 대기 호실 (${unpaidList.length}건)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AutumnTheme.textEspresso,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (unpaidList.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.check_circle_outline, color: AutumnTheme.accentForest, size: 48),
                              SizedBox(height: 8),
                              Text('이번 달 모든 호실의 월세가 완납되었습니다! 🎉',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AutumnTheme.textEspresso)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...unpaidList.map((p) => _buildUnpaidCard(p)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? const Color(0xFFFFD54F) : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUnpaidCard(Payment p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AutumnTheme.accentWine.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.roomNumber ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AutumnTheme.accentWine,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.tenantName} (납부일: 매월 ${p.payDay}일)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AutumnTheme.textEspresso),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '미납액: ${p.unpaidAmount}만원 (청구: ${p.amountExpected}만원)',
                    style: const TextStyle(fontSize: 12, color: AutumnTheme.textMuted),
                  ),
                ],
              ),
            ),
            if (p.tenantPhone != null && p.tenantPhone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy, color: AutumnTheme.primaryMaple),
                onPressed: () => _copyPhoneNumber(p.tenantPhone!),
                tooltip: '연락처 복사',
              ),
          ],
        ),
      ),
    );
  }
}

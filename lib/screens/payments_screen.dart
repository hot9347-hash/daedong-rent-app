import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/payment.dart';
import '../theme/autumn_theme.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedYm = DateFormat('yyyy-MM').format(DateTime.now());
  List<Payment> _payments = [];
  bool _isLoading = true;

  final List<String> _floors = ['전체', '2층', '3층', '4층', '5층'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _floors.length, vsync: this);
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    final list = await DbHelper.instance.getPaymentsForMonth(_selectedYm);
    setState(() {
      _payments = list;
      _isLoading = false;
    });
  }

  Future<void> _markPaid(Payment p) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await DbHelper.instance.processIncomingPayment(
      roomId: p.roomId,
      totalAmount: p.amountExpected,
      paidDate: todayStr,
      note: '수동 완납 확인',
    );
    await _loadPayments();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.roomNumber} 완납 처리되었습니다.'),
          backgroundColor: AutumnTheme.accentForest,
        ),
      );
    }
  }

  Future<void> _showEditPaymentDialog(Payment p) async {
    final paidCtrl = TextEditingController(text: p.amountPaid.toString());
    final noteCtrl = TextEditingController(text: p.note);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${p.roomNumber} (${p.tenantName}) 수납 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('청구년월: ${p.yearMonth} (청구액: ${p.amountExpected}만원)'),
            const SizedBox(height: 12),
            TextField(
              controller: paidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '실제 입금액 (만원)',
                suffixText: '만원',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: '수납 메모',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.restore, size: 18, color: AutumnTheme.accentWine),
                  label: const Text('미납(0원)으로 초기화', style: TextStyle(color: AutumnTheme.accentWine)),
                  onPressed: () {
                    paidCtrl.text = '0';
                    noteCtrl.text = '미납 초기화';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPaid = int.tryParse(paidCtrl.text.trim()) ?? 0;
              await DbHelper.instance.updatePaymentDirect(
                paymentId: p.id!,
                amountExpected: p.amountExpected,
                amountPaid: newPaid,
                note: noteCtrl.text.trim(),
              );
              if (context.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await _loadPayments();
    }
  }

  List<Payment> _getFilteredPayments(int tabIndex) {
    if (tabIndex == 0) return _payments;
    final floorPrefix = '${tabIndex + 1}';
    return _payments.where((p) => p.roomNumber != null && p.roomNumber!.startsWith(floorPrefix)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('월별 수납 현황'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AutumnTheme.primaryMaple),
                      onPressed: () {
                        final cur = DateFormat('yyyy-MM').parse(_selectedYm);
                        final prev = DateTime(cur.year, cur.month - 1);
                        setState(() => _selectedYm = DateFormat('yyyy-MM').format(prev));
                        _loadPayments();
                      },
                    ),
                    Text(
                      '$_selectedYm 월세 장부',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AutumnTheme.textEspresso,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AutumnTheme.primaryMaple),
                      onPressed: () {
                        final cur = DateFormat('yyyy-MM').parse(_selectedYm);
                        final next = DateTime(cur.year, cur.month + 1);
                        setState(() => _selectedYm = DateFormat('yyyy-MM').format(next));
                        _loadPayments();
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AutumnTheme.primaryMaple,
                labelColor: AutumnTheme.primaryMaple,
                unselectedLabelColor: AutumnTheme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: _floors.map((f) => Tab(text: f)).toList(),
                onTap: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AutumnTheme.primaryMaple))
          : TabBarView(
              controller: _tabController,
              children: List.generate(_floors.length, (index) {
                final list = _getFilteredPayments(index);
                if (list.isEmpty) {
                  return const Center(child: Text('해당 층에 수납 내역이 없습니다.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _buildPaymentCard(list[i]),
                );
              }),
            ),
    );
  }

  Widget _buildPaymentCard(Payment p) {
    Color badgeColor;
    Color textColor;
    String statusText = p.paymentStatus;

    if (p.paymentStatus == '완납') {
      badgeColor = AutumnTheme.accentForest.withOpacity(0.12);
      textColor = AutumnTheme.accentForest;
      if (p.note.contains('선납')) {
        statusText = '선납 완납';
        badgeColor = AutumnTheme.accentOchre.withOpacity(0.15);
        textColor = AutumnTheme.accentOchre;
      }
    } else if (p.paymentStatus == '부분입금') {
      badgeColor = AutumnTheme.accentOchre.withOpacity(0.15);
      textColor = AutumnTheme.accentOchre;
    } else {
      badgeColor = AutumnTheme.accentWine.withOpacity(0.12);
      textColor = AutumnTheme.accentWine;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditPaymentDialog(p),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        p.roomNumber ?? '',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AutumnTheme.textEspresso),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.tenantName ?? '(공실)',
                        style: const TextStyle(fontSize: 14, color: AutumnTheme.textMuted),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('청구: ${p.amountExpected}만원 (매월 ${p.payDay}일)',
                          style: const TextStyle(fontSize: 13, color: AutumnTheme.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        '실 입금: ${p.amountPaid}만원' + (p.paidDate.isNotEmpty ? ' (${p.paidDate})' : ''),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AutumnTheme.textEspresso),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          foregroundColor: AutumnTheme.primaryMaple,
                        ),
                        onPressed: () => _showEditPaymentDialog(p),
                        child: const Text('수정', style: TextStyle(fontSize: 12)),
                      ),
                      if (p.paymentStatus != '완납') ...[
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: AutumnTheme.primaryMaple,
                          ),
                          onPressed: () => _markPaid(p),
                          child: const Text('완납 처리', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

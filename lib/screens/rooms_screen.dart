import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../models/room.dart';
import '../theme/autumn_theme.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<Room> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    final list = await DbHelper.instance.getAllRooms();
    setState(() {
      _rooms = list;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('대동주택 호실 현황 (16세대)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AutumnTheme.primaryMaple),
            onPressed: _loadRooms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AutumnTheme.primaryMaple))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                final r = _rooms[index];
                final isVacant = r.status == '공실';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isVacant
                            ? AutumnTheme.textMuted.withOpacity(0.1)
                            : AutumnTheme.primaryMaple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          r.roomNumber.replaceAll('호', ''),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isVacant ? AutumnTheme.textMuted : AutumnTheme.primaryMaple,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          r.roomNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isVacant ? '공실' : r.tenantName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isVacant ? AutumnTheme.accentWine : AutumnTheme.textEspresso,
                            fontWeight: isVacant ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '보증금 ${r.deposit}만 / 월세 ${r.monthlyRent}만 / 관리비 ${r.maintenanceFee}만 (매월 ${r.payDay}일)',
                        style: const TextStyle(fontSize: 12, color: AutumnTheme.textMuted),
                      ),
                    ),
                    trailing: isVacant
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.copy, color: AutumnTheme.primaryMaple),
                            onPressed: () => _copyPhoneNumber(r.tenantPhone),
                            tooltip: '연락처 복사',
                          ),
                  ),
                );
              },
            ),
    );
  }
}

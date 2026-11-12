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
  String _selectedFloor = '전체';

  final List<String> _floors = ['전체', '2층', '3층', '4층', '5층'];

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

  List<Room> get _filteredRooms {
    if (_selectedFloor == '전체') return _rooms;
    final prefix = _selectedFloor.substring(0, 1); // '2', '3', '4', '5'
    return _rooms.where((r) => r.roomNumber.startsWith(prefix)).toList();
  }

  Future<void> _showEditRoomSheet(Room room) async {
    final nameCtrl = TextEditingController(text: room.tenantName);
    final phoneCtrl = TextEditingController(text: room.tenantPhone);
    final depositCtrl = TextEditingController(text: room.deposit.toString());
    final rentCtrl = TextEditingController(text: room.monthlyRent.toString());
    final feeCtrl = TextEditingController(text: room.maintenanceFee.toString());
    final payDayCtrl = TextEditingController(text: room.payDay.toString());
    final memoCtrl = TextEditingController(text: room.memo);

    String status = room.status;
    String contractType = room.contractType;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AutumnTheme.surfaceWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_note, color: AutumnTheme.primaryMaple, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              '대동주택 ${room.roomNumber} 정보 수정',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AutumnTheme.textEspresso,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // 계약 상태 및 형태 선택
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: status,
                            decoration: const InputDecoration(
                              labelText: '입주 상태',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: '계약중', child: Text('계약중')),
                              DropdownMenuItem(value: '공실', child: Text('공실')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => status = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: contractType,
                            decoration: const InputDecoration(
                              labelText: '계약 형태',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: '월세', child: Text('월세')),
                              DropdownMenuItem(value: '전세', child: Text('전세')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => contractType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 세입자 이름 & 연락처
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: '세입자 이름',
                              hintText: '예: 홍길동',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: '연락처',
                              hintText: '010-0000-0000',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 보증금, 월세, 관리비 (만원 단위)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: depositCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '보증금(만원)',
                              suffixText: '만',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: rentCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '월세(만원)',
                              suffixText: '만',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: feeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '관리비(만원)',
                              suffixText: '만',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 매월 납부일 & 메모
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: payDayCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '매월 납부일',
                              suffixText: '일',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: memoCtrl,
                            decoration: const InputDecoration(
                              labelText: '메모 / 특약사항',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text('${room.roomNumber} 정보 저장하기'),
                        onPressed: () async {
                          final updatedRoom = Room(
                            id: room.id,
                            buildingName: room.buildingName,
                            roomNumber: room.roomNumber,
                            tenantName: status == '공실' ? '' : nameCtrl.text.trim(),
                            tenantPhone: status == '공실' ? '' : phoneCtrl.text.trim(),
                            contractType: contractType,
                            deposit: int.tryParse(depositCtrl.text.trim()) ?? 0,
                            monthlyRent: contractType == '전세'
                                ? 0
                                : (int.tryParse(rentCtrl.text.trim()) ?? 0),
                            maintenanceFee: int.tryParse(feeCtrl.text.trim()) ?? 0,
                            payDay: (int.tryParse(payDayCtrl.text.trim()) ?? 5).clamp(1, 31),
                            startDate: room.startDate,
                            endDate: room.endDate,
                            memo: memoCtrl.text.trim(),
                            status: status,
                          );
                          await DbHelper.instance.updateRoom(updatedRoom);
                          if (context.mounted) {
                            Navigator.pop(ctx, true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await _loadRooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${room.roomNumber} 호실 정보가 저장되었습니다!'),
            backgroundColor: AutumnTheme.accentForest,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayRooms = _filteredRooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('대동주택 호실 관리 (터치하여 수정)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AutumnTheme.primaryMaple),
            onPressed: _loadRooms,
          ),
        ],
      ),
      body: Column(
        children: [
          // 층별 필터 칩
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _floors.map((floor) {
                final isSelected = _selectedFloor == floor;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(floor),
                    selected: isSelected,
                    selectedColor: AutumnTheme.primaryMaple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AutumnTheme.textEspresso,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _selectedFloor = floor),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AutumnTheme.primaryMaple))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: displayRooms.length,
                    itemBuilder: (context, index) {
                      final r = displayRooms[index];
                      final isVacant = r.status == '공실';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _showEditRoomSheet(r),
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
                                  fontWeight: isVacant ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              if (!isVacant && r.tenantPhone.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  r.tenantPhone,
                                  style: const TextStyle(fontSize: 12, color: AutumnTheme.textMuted),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '보증금 ${r.deposit}만 / 월세 ${r.monthlyRent}만 / 관리비 ${r.maintenanceFee}만 (매월 ${r.payDay}일)',
                              style: const TextStyle(fontSize: 12, color: AutumnTheme.textMuted),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isVacant && r.tenantPhone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20, color: AutumnTheme.textMuted),
                                  onPressed: () => _copyPhoneNumber(r.tenantPhone),
                                  tooltip: '연락처 복사',
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: AutumnTheme.primaryMaple),
                                onPressed: () => _showEditRoomSheet(r),
                                tooltip: '호실 정보 수정',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

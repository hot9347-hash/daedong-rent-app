import 'package:flutter/material.dart';
import 'theme/autumn_theme.dart';
import 'services/sms_service.dart';
import 'database/db_helper.dart';
import 'screens/dashboard_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/sms_simulation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 데이터베이스 초기화 및 대동주택 16개 호실 시드 데이터 준비
  await DbHelper.instance.database;

  // 안드로이드 SMS 감지 서비스 및 로컬 푸시 초기화
  await SmsService.instance.init();

  runApp(const DaedongRentApp());
}

class DaedongRentApp extends StatelessWidget {
  const DaedongRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '대동주택 스마트 월세관리',
      debugShowCheckedModeBanner: false,
      theme: AutumnTheme.theme,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PaymentsScreen(),
    RoomsScreen(),
    SmsSimulationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '대시보드',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '수납 장부',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: '호실 현황',
          ),
          NavigationDestination(
            icon: Icon(Icons.sms_outlined),
            selectedIcon: Icon(Icons.sms),
            label: '입금 감지',
          ),
        ],
      ),
    );
  }
}

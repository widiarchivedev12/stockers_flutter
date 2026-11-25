import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Konfigurasi routing aplikasi Stockers menggunakan go_router
/// Mendukung shell route untuk bottom navigation dan deep linking
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const _DashboardPlaceholder(),
          ),
          GoRoute(
            path: '/entries',
            name: 'entries',
            builder: (context, state) => const _EntriesPlaceholder(),
          ),
          GoRoute(
            path: '/input',
            name: 'input',
            builder: (context, state) => const _InputPlaceholder(),
          ),
          GoRoute(
            path: '/report',
            name: 'report',
            builder: (context, state) => const _ReportPlaceholder(),
          ),
          GoRoute(
            path: '/period',
            name: 'period',
            builder: (context, state) => const _PeriodPlaceholder(),
          ),
        ],
      ),
      GoRoute(
        path: '/stock/:kode',
        name: 'stock-card',
        builder: (context, state) {
          final kode = state.pathParameters['kode'] ?? '';
          return _StockCardPlaceholder(kode: kode);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const _SettingsPlaceholder(),
      ),
    ],
  );
}

/// Scaffold dengan bottom navigation bar untuk shell route
class _ScaffoldWithNavBar extends StatefulWidget {
  final Widget child;

  const _ScaffoldWithNavBar({required this.child});

  @override
  State<_ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<_ScaffoldWithNavBar> {
  int _currentIndex = 0;

  static const List<String> _destinations = [
    '/',
    '/entries',
    '/input',
    '/report',
    '/period',
  ];

  static const List<NavigationDestination> _navDestinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.list_alt_outlined),
      selectedIcon: Icon(Icons.list_alt),
      label: 'Mutasi',
    ),
    NavigationDestination(
      icon: Icon(Icons.add_box_outlined),
      selectedIcon: Icon(Icons.add_box),
      label: 'Input',
    ),
    NavigationDestination(
      icon: Icon(Icons.assessment_outlined),
      selectedIcon: Icon(Icons.assessment),
      label: 'Laporan',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Periode',
    ),
  ];

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_destinations[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _navDestinations,
      ),
    );
  }
}

/// Placeholder widgets untuk masing-masing tab (akan diganti dengan implementasi nyata)
class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: const Center(child: Text('Dashboard - Fase 0')),
    );
  }
}

class _EntriesPlaceholder extends StatelessWidget {
  const _EntriesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mutasi')),
      body: const Center(child: Text('Daftar Mutasi - Fase 0')),
    );
  }
}

class _InputPlaceholder extends StatelessWidget {
  const _InputPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Mutasi')),
      body: const Center(child: Text('Form Input Mutasi - Fase 0')),
    );
  }
}

class _ReportPlaceholder extends StatelessWidget {
  const _ReportPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: const Center(child: Text('Laporan Periode - Fase 0')),
    );
  }
}

class _PeriodPlaceholder extends StatelessWidget {
  const _PeriodPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Periode')),
      body: const Center(child: Text('Panel Periode - Fase 0')),
    );
  }
}

class _StockCardPlaceholder extends StatelessWidget {
  final String kode;

  const _StockCardPlaceholder({required this.kode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kartu Stok: $kode')),
      body: Center(child: Text('Kartu Stok untuk $kode - Fase 0')),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: const Center(child: Text('Pengaturan (Backup/Restore) - Fase 0')),
    );
  }
}
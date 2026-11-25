import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'router.dart';
import 'theme.dart';

/// Widget utama aplikasi Stockers
class StockersApp extends StatefulWidget {
  const StockersApp({super.key});

  @override
  State<StockersApp> createState() => _StockersAppState();
}

class _StockersAppState extends State<StockersApp> {
  @override
  void initState() {
    super.initState();
    // Inisialisasi format tanggal Indonesia
    initializeDateFormatting('id_ID', null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stockers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      // Lokalisasi Indonesia
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
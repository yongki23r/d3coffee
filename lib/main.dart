import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

// Inisialisasi klien Supabase global
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase menggunakan project URL Anda
  await Supabase.initialize(
    url: 'https://zkhpgjamzhotvatiggwg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpraHBnamFtemhvdHZhdGlnZ3dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkwNzE1NjcsImV4cCI6MjA5NDY0NzU2N30.Je9NB4I4Ue8ZNhioyVPnzFg3HBOdPU697RL_UaYZpeI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Ukuran standar adaptif smartphone
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'D3-Coffee POS',
          theme: ThemeData(
            primarySwatch: Colors.brown,
            scaffoldBackgroundColor: Colors.white,
            // FIX UTAMA: Mengubah tipografi teks global bawaan ke hitam/gelap agar terlihat jelas
            textTheme: Typography.blackMountainView.apply(fontSizeFactor: 1.sp),
          ),
          home: child,
        );
      },
      child: const LoginPage(),
    );
  }
}
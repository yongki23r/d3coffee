import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Mengambil instance supabase global Anda
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedShift = 'Pagi'; // Default shift untuk kasir
  bool _isAdminLogin = false;     // STATE PENENTU: false = Kasir, true = Admin
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong!'), backgroundColor: Colors.red),
      );
      return;
    }

    // --- PROSES VALIDASI LOGIN ---
    if (_isAdminLogin) {
      // Validasi Jalur Admin
      if (email != 'admin@d3coffee.com') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu ini khusus untuk akun Admin!'), backgroundColor: Colors.red),
        );
        return;
      }
    } else {
      // Validasi Jalur Kasir
      if (email == 'admin@d3coffee.com') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Admin silakan masuk melalui menu Login Admin di bawah.'), backgroundColor: Colors.orange),
        );
        return;
      }

      // Cocokkan email kasir dengan shift yang dipilih
      if (email == 'kasir_pagi@d3coffee.com' && _selectedShift != 'Pagi') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email Kasir Pagi tidak cocok dengan Shift yang dipilih!'), backgroundColor: Colors.red),
        );
        return;
      }
      if (email == 'kasir_malam@d3coffee.com' && _selectedShift != 'Malam') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email Kasir Malam tidak cocok dengan Shift yang dipilih!'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Login ke Supabase
      await supabase.auth.signInWithPassword(email: email, password: password);

      if (mounted) {
        // Berhasil Login -> Pindah ke HomePage membawa data shift
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              // Jika login admin, kirim string 'Admin', jika kasir kirim sesuai shift-nya
              shift: _isAdminLogin ? 'Admin' : _selectedShift,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EFEA), // Warna background krem hangat khas kopi
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO D3 COFFEE
                Icon(Icons.local_cafe, size: 80.sp, color: const Color(0xFF704F3D)),
                SizedBox(height: 16.h),
                Text(
                  'D3 COFFEE',
                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4A3728)),
                ),
                Text(
                  _isAdminLogin ? 'Sistem POS - Login Admin' : 'Sistem Point of Sale',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 32.h),

                // TEXTFIELD EMAIL
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF704F3D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),

                // TEXTFIELD PASSWORD
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF704F3D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),

                // TAMPILKAN PILIHAN SHIFT HANYA JIKA BUKAN LOGIN ADMIN
                if (!_isAdminLogin) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedShift,
                    decoration: InputDecoration(
                      labelText: 'Pilih Shift',
                      prefixIcon: const Icon(Icons.access_time, color: Color(0xFF704F3D)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Pagi', child: Text('Shift Pagi')),
                      DropdownMenuItem(value: 'Malam', child: Text('Shift Malam')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedShift = value!;
                      });
                    },
                  ),
                  SizedBox(height: 24.h),
                ] else ...[
                  // Beri jarak ekstra jika dropdown shift disembunyikan
                  SizedBox(height: 8.h),
                ],

                // TOMBOL UTAMA LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF704F3D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      _isAdminLogin ? 'LOGIN ADMIN' : 'LOGIN KASIR',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // TOMBOL TOGGLE (Pindah Menu Kasir <=> Admin)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isAdminLogin = !_isAdminLogin; // Balikkan nilai boolean
                      _emailController.clear();       // Bersihkan form agar rapi
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    _isAdminLogin ? 'Kembali ke Login Kasir' : 'Login sebagai Admin',
                    style: TextStyle(
                      color: const Color(0xFF4A3728),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'main.dart'; // Mengambil instance supabase global
import 'revenue_report_page.dart';
import 'login_page.dart';
import 'manage_menu_page.dart';
import 'transaction_log_page.dart';

class HomePage extends StatefulWidget {
  final String shift;

  const HomePage({super.key, required this.shift});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isAdmin = false;
  bool _isLoading = false;
  List<dynamic> _products = [];

  // State untuk Keranjang Belanja
  final Map<String, int> _cart = {};
  double _totalHarga = 0.0;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _fetchProducts();
  }

  void _checkUserRole() {
    final user = supabase.auth.currentUser;
    if (user != null && (user.email == 'admin@d3coffee.com' || widget.shift == 'Admin')) {
      setState(() {
        _isAdmin = true;
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase.from('products').select().order('name', ascending: true);
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat menu: $e')),
        );
      }
    }
  }

  void _addToCart(String productId, double price) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + 1;
      _calculateTotal();
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId] == 1) {
          _cart.remove(productId);
        } else {
          _cart[productId] = _cart[productId]! - 1;
        }
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double tempTotal = 0.0;
    _cart.forEach((id, qty) {
      final product = _products.firstWhere((p) => p['id'].toString() == id);
      double price = (product['price'] ?? 0).toDouble();
      tempTotal += price * qty;
    });
    _totalHarga = tempTotal;
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _totalHarga = 0.0;
    });
  }

  void _showPaymentDialog() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong!')),
      );
      return;
    }

    final TextEditingController cashController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFF3E5F5),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran',
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Total: Rp $_totalHarga',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: cashController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Uang Tunai',
                    prefixText: 'Rp ',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal', style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF704F3D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        double cashInput = double.tryParse(cashController.text) ?? 0;
                        if (cashInput < _totalHarga) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Uang tunai tidak cukup!'), backgroundColor: Colors.red),
                          );
                        } else {
                          Navigator.pop(context);
                          _processPayment(cashInput);
                        }
                      },
                      child: const Text('Proses', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processPayment(double cash) async {
    setState(() => _isLoading = true);

    // Simpan nilai total sebelum cart dikosongkan
    final double finalTotal = _totalHarga;
    double kembalian = cash - finalTotal;

    List<String> itemDetailList = [];
    _cart.forEach((id, qty) {
      final product = _products.firstWhere((p) => p['id'].toString() == id);
      itemDetailList.add("${product['name']} x$qty");
    });
    String itemsSummary = itemDetailList.join(', ');

    try {
      await supabase.from('log_transactions').insert({
        'total': finalTotal,
        'cash': cash,
        'change': kembalian,
        'shift': widget.shift,
        'details': itemsSummary, // Menggunakan 'details' sesuai skema database
      });

      if (mounted) {
        _showReceiptDialog(finalTotal, cash, kembalian, itemDetailList);
        _clearCart(); // Kosongkan cart setelah transaksi berhasil dan data disimpan
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaksi Gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReceiptDialog(double total, double cash, double change, List<String> items) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.brown),
                    SizedBox(width: 8.w),
                    Text('Pratinjau Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  ],
                ),
                const Divider(),
                Container(
                  padding: EdgeInsets.all(8.w),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.grey[50],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 260.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Text('D3 - COFFEE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp))),
                          Center(child: Text('Jl. Raya Kafe No. 3', style: TextStyle(fontSize: 11.sp))),
                          Center(child: Text('Shift: ${widget.shift}', style: TextStyle(fontSize: 11.sp))),
                          const Text('------------------------------------------'),
                          ...items.map((item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            child: Text(item, style: TextStyle(fontSize: 12.sp, fontFamily: 'monospace')),
                          )),
                          const Text('------------------------------------------'),
                          Text('TOTAL: Rp $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('TUNAI: Rp $cash'),
                          Text('KEMBALIAN: Rp $change'),
                          const Text('------------------------------------------'),
                          Center(child: Text('Terima Kasih!', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.sp))),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup', style: TextStyle(color: Colors.black54)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                      onPressed: () async {
                        await _printPdfReceipt(total, cash, change, items, widget.shift);
                      },
                      icon: const Icon(Icons.print, color: Colors.white, size: 16),
                      label: const Text('Cetak PDF', style: TextStyle(color: Colors.white)),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _printPdfReceipt(double total, double cash, double change, List<String> items, String shift) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Format roll thermal 80mm
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('D3 - COFFEE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20))),
              pw.Center(child: pw.Text('Jl. Parit H. Husin 1 No.7', style: const pw.TextStyle(fontSize: 12))),
              pw.Center(child: pw.Text('Shift: $shift', style: const pw.TextStyle(fontSize: 12))),
              pw.Divider(),
              ...items.map((item) => pw.Text(item, style: const pw.TextStyle(fontSize: 14))),
              pw.Divider(),
              pw.Text('TOTAL: Rp $total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('TUNAI: Rp $cash', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('KEMBALIAN: Rp $change', style: const pw.TextStyle(fontSize: 14)),
              pw.Divider(),
              pw.Center(child: pw.Text('Terima Kasih!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 12))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Kasir - ${widget.shift}', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.brown,
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.coffee, color: Colors.brown, size: 30),
              ),
              accountName: Text(_isAdmin ? 'Administrator' : 'Kasir POS'),
              accountEmail: Text(supabase.auth.currentUser?.email ?? '-'),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.brown),
              title: const Text('Halaman Utama'),
              onTap: () => Navigator.pop(context),
            ),
            if (_isAdmin) ...[
              const Divider(),
              Padding(
                padding: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 4.h),
                child: Text('Menu Admin', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_document, color: Colors.brown),
                title: const Text('Kelola Menu (Tambah/Hapus)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageMenuPage()),
                  ).then((_) => _fetchProducts());
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt, color: Colors.brown),
                title: const Text('Log Transaksi'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionLogPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.brown),
                title: const Text('Laporan Pendapatan'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RevenueReportPage()),
                  );
                },
              ),
            ],
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar Aplikasi', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : Column(
        children: [
          Expanded(
            child: _products.isEmpty
                ? const Center(child: Text('Menu belum tersedia.'))
                : GridView.builder(
              padding: EdgeInsets.all(12.w),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final item = _products[index];
                final id = item['id'].toString();
                final qtyInCart = _cart[id] ?? 0;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias, // Mencegah efek sentuhan melebar keluar dari lengkungan kartu
                  child: InkWell(
                    onTap: () => _addToCart(id, (item['price'] ?? 0).toDouble()), // Menangkap klik pada area kartu
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.local_cafe, size: 40.sp, color: Colors.brown[400]),
                          Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp), textAlign: TextAlign.center),
                          Text('Rp ${item['price']}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (qtyInCart > 0) ...[
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeFromCart(id),
                                ),
                                Text('$qtyInCart', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                              ],
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.brown),
                                onPressed: () => _addToCart(id, (item['price'] ?? 0).toDouble()),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Belanja:', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
                      Text('Rp $_totalHarga', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.brown[900])),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A3728),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _totalHarga > 0 ? _showPaymentDialog : null,
                      child: Text('BAYAR', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
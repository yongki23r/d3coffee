import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'main.dart'; // Mengambil instance supabase global

class TransactionLogPage extends StatefulWidget {
  const TransactionLogPage({super.key});

  @override
  State<TransactionLogPage> createState() => _TransactionLogPageState();
}

class _TransactionLogPageState extends State<TransactionLogPage> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  // Mengambil data log transaksi dari Supabase
  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('log_transactions')
          .select()
          .order('created_at', ascending: false); // Urutkan dari yang terbaru

      if (mounted) {
        setState(() {
          _transactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat log transaksi: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Fungsi Generator & Cetak PDF (Sama persis dengan spesifikasi mesin kasir)
  Future<void> _printPdfReceipt(Map<String, dynamic> tx) async {
    final pdf = pw.Document();

    // Mengubah data text details (Format: "Kopi x2, Teh x1") menjadi list untuk tata letak PDF
    final String detailsText = tx['details'] ?? '-';
    final List<String> items = detailsText.split(', ').map((e) => e.trim()).toList();

    // Ambil variabel pendukung transaksi
    final double total = (tx['total'] ?? 0).toDouble();
    final double cash = (tx['cash'] ?? 0).toDouble();
    final double change = (tx['change'] ?? 0).toDouble();
    final String shift = tx['shift'] ?? '-';
    final String createdAt = tx['created_at'] != null
        ? tx['created_at'].toString().substring(0, 16).replaceAll('T', ' ')
        : '-';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Format roll thermal 80mm standar struk kasir
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('D3 - COFFEE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
              pw.Center(child: pw.Text('Jl. Parit H. Husin 1 No.7', style: const pw.TextStyle(fontSize: 11))),
              pw.Center(child: pw.Text('Shift: $shift', style: const pw.TextStyle(fontSize: 11))),
              pw.Center(child: pw.Text('Waktu: $createdAt', style: const pw.TextStyle(fontSize: 10))),
              pw.Center(child: pw.Text('* REPRINT STRUK *', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
              pw.Divider(),
              ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(item, style: const pw.TextStyle(fontSize: 12)),
              )),
              pw.Divider(),
              pw.Text('TOTAL: Rp $total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text('TUNAI: Rp $cash', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('KEMBALIAN: Rp $change', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(),
              pw.Center(child: pw.Text('Terima Kasih!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 11))),
            ],
          );
        },
      ),
    );

    // Membuka dialog print bawaan sistem operasi / HP
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Log Transaksi', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTransactions,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : _transactions.isEmpty
          ? const Center(child: Text('Belum ada riwayat transaksi.'))
          : ListView.builder(
        padding: EdgeInsets.all(12.w),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];

          // Format waktu tanggal pembuatannya
          final String dateStr = tx['created_at'] != null
              ? tx['created_at'].toString().substring(0, 10)
              : '-';
          final String timeStr = tx['created_at'] != null
              ? tx['created_at'].toString().substring(11, 16)
              : '-';

          return Card(
            color: Colors.white,
            margin: EdgeInsets.only(bottom: 10.h),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt, color: Colors.brown, size: 20),
                          SizedBox(width: 6.w),
                          Text(
                            'ID Transaksi: #${tx['id']}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.brown[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Shift: ${tx['shift']}',
                          style: TextStyle(fontSize: 11.sp, color: Colors.brown[900], fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                  const Divider(),
                  SizedBox(height: 2.h),
                  Text(
                    'Pesanan:',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  Text(
                    '${tx['details']}',
                    style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pendapatan:',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                          ),
                          Text(
                            'Rp ${tx['total']}',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.green[700]),
                          ),
                          Text(
                            '$dateStr pukul $timeStr',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      // Tombol Cetak Ulang Struk
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        ),
                        onPressed: () async {
                          await _printPdfReceipt(tx);
                        },
                        icon: const Icon(Icons.print, size: 16),
                        label: Text('Cetak Kembali', style: TextStyle(fontSize: 12.sp)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
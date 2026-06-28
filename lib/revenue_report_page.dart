import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'main.dart'; // Mengambil instance supabase global Anda

class RevenueReportPage extends StatefulWidget {
  const RevenueReportPage({super.key});

  @override
  State<RevenueReportPage> createState() => _RevenueReportPageState();
}

class _RevenueReportPageState extends State<RevenueReportPage> {
  bool _isLoading = true;
  Map<String, double> _dailyRevenue = {};
  Map<String, double> _monthlyRevenue = {};

  double _totalSemuaPendapatan = 0;

  final List<String> _namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAndProcessTransactions();
  }

  Future<void> _fetchAndProcessTransactions() async {
    try {
      // Mengambil semua log transaksi dari yang terbaru
      final response = await supabase
          .from('log_transactions')
          .select()
          .order('created_at', ascending: false);

      Map<String, double> tempDaily = {};
      Map<String, double> tempMonthly = {};
      double tempTotalSemua = 0;

      for (var item in response) {
        double totalBelanja = (item['total'] ?? 0).toDouble();
        tempTotalSemua += totalBelanja;

        // Ambil string tanggal (Supabase default: yyyy-MM-ddTHH:mm:ss...)
        String createdAt = item['created_at'] ?? DateTime.now().toIso8601String();
        DateTime date = DateTime.parse(createdAt).toLocal();

        // Format Kunci Harian: "Tanggal Bulan Tahun" (Contoh: 2 Juni 2026)
        String dayKey = "${date.day} ${_namaBulan[date.month - 1]} ${date.year}";
        tempDaily[dayKey] = (tempDaily[dayKey] ?? 0) + totalBelanja;

        // Format Kunci Bulanan: "Bulan Tahun" (Contoh: Juni 2026)
        String monthKey = "${_namaBulan[date.month - 1]} ${date.year}";
        tempMonthly[monthKey] = (tempMonthly[monthKey] ?? 0) + totalBelanja;
      }

      setState(() {
        _dailyRevenue = tempDaily;
        _monthlyRevenue = tempMonthly;
        _totalSemuaPendapatan = tempTotalSemua;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat laporan pendapatan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Laporan Pendapatan', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
          backgroundColor: Colors.brown,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.brown[200],
            indicatorColor: Colors.white,
            tabs: [
              Tab(child: Text('Harian', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold))),
              Tab(child: Text('Bulanan', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.brown))
            : Column(
          children: [
            // Rangkuman Total Pendapatan Kotor Keseluruhan
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.brown[700],
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Omset Keseluruhan', style: TextStyle(color: Colors.brown[100], fontSize: 13.sp)),
                  SizedBox(height: 4.h),
                  Text('Rp $_totalSemuaPendapatan', style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Daftar List Pendapatan Harian / Bulanan
            Expanded(
              child: TabBarView(
                children: [
                  _buildRevenueList(_dailyRevenue, Icons.calendar_today),
                  _buildRevenueList(_monthlyRevenue, Icons.calendar_month),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueList(Map<String, double> data, IconData icon) {
    if (data.isEmpty) {
      return Center(
        child: Text('Belum ada data transaksi tercatat.', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
      );
    }

    final keys = data.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final period = keys[index];
        final amount = data[period];

        return Card(
          color: Colors.white,
          margin: EdgeInsets.only(bottom: 10.h),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.brown[50],
              child: Icon(icon, color: Colors.brown),
            ),
            title: Text(period, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black)),
            trailing: Text(
              'Rp $amount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.green[700]),
            ),
          ),
        );
      },
    );
  }
}
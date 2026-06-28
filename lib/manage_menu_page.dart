import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'main.dart';

class ManageMenuPage extends StatefulWidget {
  const ManageMenuPage({super.key});

  @override
  State<ManageMenuPage> createState() => _ManageMenuPageState();
}

class _ManageMenuPageState extends State<ManageMenuPage> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Mengambil SEMUA produk dari database
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('products').select().order('name', ascending: true);
      if (mounted) {
        setState(() {
          _products = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memuat data menu')));
        setState(() => _isLoading = false);
      }
    }
  }

  // Fungsi Menghapus Produk
  Future<void> _deleteProduct(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Hapus Menu?', style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus menu ini?', style: TextStyle(color: Colors.black87, fontSize: 14.sp)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Batal', style: TextStyle(color: Colors.brown[700], fontSize: 14.sp))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await supabase.from('products').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu berhasil dihapus')));
        _fetchProducts(); // Refresh daftar setelah dihapus
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menghapus. Data mungkin terhubung dengan transaksi.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  // Dialog Menambah Produk
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Mencegah dialog ditutup saat proses loading
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Tambah Menu Baru', style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.black, fontSize: 14.sp),
                  decoration: InputDecoration(
                    labelText: 'Nama Produk',
                    labelStyle: TextStyle(color: Colors.brown, fontSize: 14.sp),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.brown, width: 2.0)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.black, fontSize: 14.sp),
                  decoration: InputDecoration(
                    labelText: 'Harga (Rp)',
                    labelStyle: TextStyle(color: Colors.brown, fontSize: 14.sp),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.brown, width: 2.0)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Batal', style: TextStyle(color: Colors.brown[700], fontSize: 14.sp))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0;

                if (name.isNotEmpty && price > 0) {
                  try {
                    // 1. Masukkan data ke database terlebih dahulu
                    await supabase.from('products').insert({
                      'name': name,
                      'price': price,
                      'is_active': true,
                    });

                    // 2. Pastikan halaman masih aktif
                    if (mounted) {
                      // 3. Tutup dialog SETELAH berhasil
                      Navigator.pop(dialogContext);

                      // 4. Tampilkan pesan sukses
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu berhasil ditambahkan')));

                      // 5. Refresh data (Sekarang pasti akan tereksekusi!)
                      _fetchProducts();
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(dialogContext); // Tetap tutup dialog jika gagal
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambah menu: $e')));
                    }
                  }
                } else {
                  // Validasi jika input kosong atau harga 0
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Nama dan Harga tidak boleh kosong!'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('Simpan', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Kelola Menu', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            color: Colors.white,
            margin: EdgeInsets.only(bottom: 12.h),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.brown[100],
                child: const Icon(Icons.local_cafe, color: Colors.brown),
              ),
              title: Text(product['name'], style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              subtitle: Text('Rp ${product['price']}', style: TextStyle(color: Colors.black54, fontSize: 12.sp)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteProduct(product['id']),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Menu', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
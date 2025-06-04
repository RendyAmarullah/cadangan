import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

class TambahMinumanScreen extends StatefulWidget {
  @override
  _TambahMinumanScreenState createState() => _TambahMinumanScreenState();
}

class _TambahMinumanScreenState extends State<TambahMinumanScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  File? _imageFile;

  late Client _client;
  late Storage _storage;
  late Databases _databases;
  String _productImageUrl = '';

  final String projectId = '681aa0b70002469fc157'; // Ganti sesuai Project ID
  final String databaseId = '681aa33a0023a8c7eb1f'; // Ganti sesuai Database ID
  final String collectionId = '6840abc70007d81ad734'; // Ganti sesuai Collection ID
  final String bucketId = '681aa16f003054da8969'; // Ganti sesuai Bucket ID

  @override
  void initState() {
    super.initState();
    _client = Client()
      ..setEndpoint('https://fra.cloud.appwrite.io/v1')
      ..setProject(projectId)
      ..setSelfSigned(status: true);

    _storage = Storage(_client);
    _databases = Databases(_client);
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();

      final inputFile = InputFile.fromPath(path: _imageFile!.path);

      final result = await _storage.createFile(
        bucketId: bucketId,
        file: inputFile,
        fileId: fileId,
      );

      final fileViewUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/${result.$id}/view?project=$projectId';

      setState(() {
        _productImageUrl = fileViewUrl;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _addProduct() async {
    String name = _nameController.text.trim();
    String price = _priceController.text.trim();

    if (name.isEmpty || price.isEmpty || _productImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Semua kolom harus diisi')));
      return;
    }

    try {
      await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: 'unique()', // Generate unique ID
        data: {
          'name': name,
          'price': int.parse(price),
          'productImageUrl': _productImageUrl,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil ditambahkan')));
      _clearForm();
    } catch (e) {
      print('Error adding product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan produk')));
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    setState(() {
      _imageFile = null;
      _productImageUrl = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Produk'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Produk'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: 'Masukkan nama produk'),
            ),
            SizedBox(height: 16),
            Text('Harga Produk'),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: 'Masukkan harga produk'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pilih Gambar Produk'),
            ),
            SizedBox(height: 16),
            if (_imageFile != null)
              Image.file(_imageFile!, height: 100),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _uploadImage();
                await _addProduct();
              },
              child: Text('Tambah Produk'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/AkunScreen.dart';
import 'package:pemesanan/SplahScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Client _client;
  late Storage _storage;
  late Account _account;
  late Databases _databases;
  File? _imageFile;
  String? _profileImageUrl;
  String? _userName;
  models.Session? _session;
  models.User? _currentUser;

  final String databaseId = '681aa33a0023a8c7eb1f';
  final String collectionId = '681aa352000e7e9b76b5';
  final String bucketId = '681aa16f003054da8969';
  final String projectId = '681aa0b70002469fc157';

  @override
  void initState() {
    super.initState();
    _client = Client();
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId)
        .setSelfSigned(status: true);

    _storage = Storage(_client);
    _account = Account(_client);
    _databases = Databases(_client);

    _loadProfileData();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImage();
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

      await _saveProfileImage(result.$id);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _saveProfileImage(String fileId) async {
    try {
      final userId = _currentUser?.$id;
      if (userId == null) return;

      try {
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: userId,
          data: {'profile_image': fileId},
        );
      } catch (e) {
        await _databases.createDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: userId,
          data: {'profile_image': fileId},
        );
      }

      print("Profile image updated successfully.");
    } catch (e) {
      print('Error saving profile image: $e');
    }
  }

  Future<void> _loadProfileData() async {
    final session = await _account.get();
    final userId = session.$id;

    try {
      final profileDoc = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: userId,
      );

      final profileImageId = profileDoc.data['profile_image'];
      if (profileImageId != null) {
        final fileViewUrl =
            'https://fra.cloud.appwrite.io/v1/storage/buckets/681aa16f003054da8969/files/$profileImageId/view?project=$projectId';
        setState(() {
          _profileImageUrl = fileViewUrl;
        });
      }

      final userDetailDoc = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: '684083800031dfaaecad',
        documentId: userId,
      );

      final name = userDetailDoc.data['name'];
      if (name != null) {
        setState(() {
          _userName = name;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text('Akun', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    child: _profileImageUrl != null
                        ? CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(_profileImageUrl!))
                        : const CircleAvatar(
                            radius: 60, child: Icon(Icons.person)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  _userName ?? 'Guest',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    _buildMenuItem('Alamat Tersimpan'),
                    Divider(color: Colors.black, indent: 15, endIndent: 15),
                    _buildMenuItem('Akun Saya', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AkunScreen()),
                      );
                    }),
                    Divider(color: Colors.black, indent: 15, endIndent: 15),
                    _buildMenuItem('Favorit'),
                    Divider(color: Colors.black, indent: 15, endIndent: 15),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Butuh Bantuan?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                title: Text('For Customer Service (chat only)'),
                subtitle: Text('0831 - 8274 - 2991'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _account.deleteSession(sessionId: 'current');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SplashScreen()),
                    );
                  } catch (e) {
                    print('Logout gagal: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal logout, coba lagi.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text(
                  "KELUAR",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {Function()? onTap}) {
    return ListTile(
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}

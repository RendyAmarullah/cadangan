import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/AkunScreen.dart';  // Import AkunScreen
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
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String collectionId = '681aa352000e7e9b76b5';
  final String projectId = '681aa0b70002469fc157';

  @override
  void initState() {
    super.initState();
    _client = Client();
    _storage = Storage(_client);
    _account = Account(_client);
    _databases = Databases(_client);

    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject('681aa0b70002469fc157')
        .setSelfSigned(status: true);

    _loadProfileData();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
      final bucketId = '681aa16f003054da8969';

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
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final document = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.uid,
        );

        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.uid,
          data: {'profile_image': fileId},
        );

        print("Profile image updated in the database successfully.");
      } catch (e) {
        if (e.toString().contains('document_not_found')) {
          await _databases.createDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: user.uid,
            data: {'profile_image': fileId},
          );

          print("Profile image saved to the database successfully.");
        } else {
          print('Error: $e');
        }
      }
    }
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final documentSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (documentSnapshot.exists) {
          final data = documentSnapshot.data() as Map<String, dynamic>;
          setState(() {
            _userName = data['name'];
          });
        }

        final document = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.uid,
        );

        final profileImageId = document.data['profile_image'];
        if (profileImageId != null) {
          final fileViewUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/681aa16f003054da8969/files/$profileImageId/view?project=$projectId';
          setState(() {
            _profileImageUrl = fileViewUrl;
          });
        }
      } catch (e) {
        print('Error loading profile data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text('Akun', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
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
                      ? CircleAvatar(radius: 60, backgroundImage: NetworkImage(_profileImageUrl!))
                      : const CircleAvatar(radius: 60, child: Icon(Icons.person)),
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(
                    child: Text(
                      _userName ?? '${user?.displayName ?? 'Guest'}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black, 
                width: 2.0,  
              ),
              borderRadius: BorderRadius.circular(20), 
            ),
              child: Column(
                children: [
                  
                  SizedBox(height: 10),
                  _buildMenuItem('Alamat Tersimpan'),
                   Divider(color: Colors.black ,  indent: 15, endIndent: 15,) ,
                  _buildMenuItem('Akun Saya', onTap: () {
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AkunScreen()), 
                    );
                  }),
                  Divider(color: Colors.black ,  indent: 15, endIndent: 15,) ,
                  _buildMenuItem('Favorit'),
                  Divider(color: Colors.black ,  indent: 15, endIndent: 15,) ,
                  
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
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text("KELUAR", style: TextStyle(color: Colors.white)),
            ),
          ],
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

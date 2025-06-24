import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/SplahScreen.dart';

class AkunScreen extends StatefulWidget {
  @override
  _AkunScreenState createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  late Client _client;
  late Storage _storage;
  late Account _account;
  late Databases _databases;
  File? _imageFile;
  String? _profileImageUrl;
  String? _userName;
  String? _userEmail;
  String? _noHp;
  String? _gender;
  models.Session? _session;
  models.User? _currentUser;

  final String databaseId = '681aa33a0023a8c7eb1f';
  final String collectionId = '681aa352000e7e9b76b5';
  final String profil = '684083800031dfaaecad';
  final String bucketId = '681aa16f003054da8969';
  final String projectId = '681aa0b70002469fc157';

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _noHandPhoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool _isEditing = false;

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

  Future<void> _loadProfileData() async {
    try {
      _session = await _account.getSession(sessionId: 'current');
      _currentUser = await _account.get();

      final userId = _currentUser?.$id;
      if (userId != null) {
        // Fetch profile data (image, email, gender) from the current collection
        final profileDoc = await _databases.getDocument(
          databaseId: databaseId,
          collectionId:
              collectionId, // Collection containing profile image, email, gender
          documentId: userId,
        );

        final profileImageId = profileDoc.data['profile_image'];
        if (profileImageId != null) {
          final fileViewUrl =
              'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/$profileImageId/view?project=$projectId';
          setState(() {
            _profileImageUrl = fileViewUrl;
          });
        }

        setState(() {});

        // Fetch username from a different collection
        final userNameDoc = await _databases.getDocument(
          databaseId: databaseId,
          collectionId:
              '684083800031dfaaecad', // Different collection for username
          documentId: userId,
        );

        final userName = userNameDoc.data['name'];
        final userEmail = userNameDoc.data['email'];
        final noHp = userNameDoc.data['noHandphone'];

        setState(() {
          _userName = userName;
          _userEmail = userEmail;
          _noHp = noHp;
        });

        // Set the text fields with the fetched data
        _nameController.text = _userName ?? '';
        _emailController.text = _userEmail ?? '';
        _noHandPhoneController.text = _gender ?? '';
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _updateProfile() async {
  try {
    final updatedName = _nameController.text;
    final updatedEmail = _emailController.text;
    final updatedNoHandphone = _noHandPhoneController.text;
    final updatedPassword = _passwordController.text;

    final user = await _account.get();
    if (user != null) {
      // Update the email in Appwrite's authentication system
      await _account.updateEmail(
        
        email: updatedEmail,
        password: _passwordController.text, 
      );

      // Update the email and name in your custom database
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: profil,
        documentId: user.$id,
        data: {
          'name': updatedName,
          'email': updatedEmail, // Update the email in the collection too
          'noHandphone': updatedNoHandphone,
        },
      );

      setState(() {
        _userName = updatedName;
        _userEmail = updatedEmail;

        _isEditing = false; 
      });

     
      await _account.deleteSession(sessionId: 'current');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated and logged out. Please log in again.')),
      );

     
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()), 
      );

      print("Profile updated successfully.");
    }
  } catch (e) {
    print('Error updating profile: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating profile: $e')),
    );
  }
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

      final fileViewUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/${result.$id}/view?project=$projectId';

      setState(() {
        _profileImageUrl = fileViewUrl;
      });

      await _saveProfileImage(result.$id);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _saveProfileImage(String fileId) async {
    final user = await _account.get();
    if (user != null) {
      try {
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.$id,
          data: {'profile_image': fileId},
        );
        print("Profile image updated in the database successfully.");
      } catch (e) {
        print('Error saving profile image: $e');
      }
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
          padding: const EdgeInsets.all(16.0),
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
              _isEditing
                  ? Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Name'),
                        ),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email'),
                        ),
                        TextField(
                          controller: _noHandPhoneController,
                          decoration: InputDecoration(labelText: 'No Handphone'),
                        ),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: 'Konfirmasi Password'),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          child: Text('Simpan Perubahan'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nama',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.green),
                            ),
                          ),
                          _buildMenuItem(_userName ?? 'Guest'),
                          Divider(color: Colors.black, indent: 15, endIndent: 15),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.green),
                            ),
                          ),
                          _buildMenuItem(_userEmail ?? 'Guest'),
                          Divider(color: Colors.black, indent: 15, endIndent: 15),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No Handphone',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.green),
                            ),
                          ),
                          _buildMenuItem(_noHp ?? '-'),
                          Divider(color: Colors.black, indent: 15, endIndent: 15),
                          SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            child: Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                          ),
                        ],
                      ),
                    ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {Function()? onTap}) {
    return ListTile(
      title: Text(title),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.white,
      ),
      onTap: onTap,
    );
  }
}

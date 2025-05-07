import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/SplahScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Client _client;
  late Storage _storage;
  late Account _account;
  late Databases _databases;  // Correct Database service for storing profile data
  File? _imageFile;
  String? _profileImageUrl;  // To store the image URL for displaying
  String? _userName;
  // Define your databaseId and collectionId
  final String databaseId = '681aa33a0023a8c7eb1f';  // Replace with your database ID
  final String collectionId = '681aa352000e7e9b76b5'; // Replace with your collection ID
  final String projectId = '681aa0b70002469fc157';
  @override
  void initState() {
    super.initState();
    _client = Client();
    _storage = Storage(_client);
    _account = Account(_client);
    _databases = Databases(_client); // Initialize Databases service

    // Initialize the Appwrite client
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1') // Replace with your Appwrite endpoint
        .setProject('681aa0b70002469fc157') // Replace with your Appwrite project ID
        .setSelfSigned(status: true); // Enable for local testing (remove in production)

    // Load the profile image URL when the screen is initialized
    _loadProfileData();
  }

  // Function to pick an image from gallery
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

  // Function to upload image to Appwrite Storage
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final fileId = DateTime.now().millisecondsSinceEpoch.toString(); // Unique file ID
      final bucketId = '681aa16f003054da8969'; // Ganti dengan ID bucket Anda

      // Create InputFile from path
      final inputFile = InputFile.fromPath(path: _imageFile!.path);

      // Upload file to Appwrite Storage
      final result = await _storage.createFile(
        bucketId: bucketId,  // ID bucket
        file: inputFile,      // File to upload
        fileId: fileId,       // Unique file ID
      );

      // Check if successful
      print('File uploaded: ${result.$id}');  // ID of the uploaded file

      // After successful upload, save file ID in the database
      await _saveProfileImage(result.$id);
      
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  // Save the profile image ID in the user's document in the Database
  Future<void> _saveProfileImage(String fileId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Check if the document exists first
        final document = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.uid, // Use the user's UID as the documentId
        );

        // If the document exists, update it
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.uid,
          data: {'profile_image': fileId}, // Save file ID
        );

        print("Profile image updated in the database successfully.");
      } catch (e) {
        // If document does not exist, create it
        if (e.toString().contains('document_not_found')) {
          await _databases.createDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: user.uid, // Using UID as document ID
            data: {
              'profile_image': fileId,  // Save the file ID
            },
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
        // Fetch the user's data from Firebase
         final documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
        if (documentSnapshot.exists) {
        // Assuming that the data is stored with 'email', 'name', 'password' fields
        final data = documentSnapshot.data() as Map<String, dynamic>;
        
        setState(() {
          _userName = data['name']; // Set the name
          // Set the email
          // _password = data['password']; // We don't usually display passwords for security reasons
        });
      } 
        

        // Also load the profile image from Appwrite
        final document = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.uid, // Use the user's UID as the documentId
        );

        final profileImageId = document.data['profile_image'];
        if (profileImageId != null) {
          final fileViewUrl =
              'https://fra.cloud.appwrite.io/v1/storage/buckets/681aa16f003054da8969/files/$profileImageId/view?project=$projectId';

          setState(() {
            _profileImageUrl = fileViewUrl; // Store the file URL for displaying
          });
        }
      } catch (e) {
        print('Error loading profile data: $e');
      }
    }
  }

  // Load the profile image URL from Appwrite Storage
//  Future<void> _loadProfileImage() async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user != null) {
//     try {
//       final document = await _databases.getDocument(
//         databaseId: databaseId,
//         collectionId: collectionId,
//         documentId: user.uid, // Use the user's UID as the documentId
//       );

//       final profileImageId = document.data['profile_image'];
//       if (profileImageId != null) {
//         // Construct the file view URL
//         final fileViewUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/681aa16f003054da8969/files/$profileImageId/view?project=$projectId';

//         setState(() {
//           _profileImageUrl = fileViewUrl; // Store the file URL for displaying
//         });
//       }
//     } catch (e) {
//       print('Error loading profile image: $e');
//     }
//   }
// }


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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Image and Name Section
            Center(
              child: GestureDetector(
                onTap: _pickImage,  // Function to pick an image
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
                _userName ?? '${user?.displayName ?? 'Guest'}', // Replace with dynamic username if available
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),

            // List of Menu Items
            _buildMenuItem('Alamat Tersimpan'),
            _buildMenuItem('Akun Saya'),
            _buildMenuItem('Favorit'),

            SizedBox(height: 20),

            // Customer Service Section
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
              onTap: () {
                // Add functionality to open WhatsApp or chat
              },
            ),
            SizedBox(height: 30),

            // Log Out Button
            ElevatedButton(
  onPressed: () async {
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Navigate back to the Splash screen or Login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignUpScreen()),  // Navigate to SplashScreen or Login screen
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue, // Blue color for the button
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

  // Helper method to build the list items in the profile menu
  Widget _buildMenuItem(String title) {
    return ListTile(
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {
        // Handle navigation or action when tapped
      },
    );
  }
}

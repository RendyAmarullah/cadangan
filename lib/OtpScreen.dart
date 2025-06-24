// import 'package:flutter/material.dart';
// import 'package:appwrite/appwrite.dart';
// import 'package:appwrite/models.dart' as models;
// import 'package:pemesanan/SplahScreen.dart';

// class OtpInputScreen extends StatefulWidget {
//   final String userId;

//   OtpInputScreen({required this.userId});

//   @override
//   _OtpInputScreenState createState() => _OtpInputScreenState();
// }

// class _OtpInputScreenState extends State<OtpInputScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _otpController = TextEditingController();
//   bool _isLoading = false;

//   final Client _client = Client().setEndpoint('https://cloud.appwrite.io/v1').setProject('681aa0b70002469fc157');
//   late final Account _account = Account(_client);

//   Future<void> _verifyOtp() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Verify OTP for the user
//       final otp = _otpController.text.trim();
//       final response = await _account.verifyOtp(otp: otp);

//       // If OTP is correct, proceed to the next screen (e.g., SplashScreen)
//       if (response != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('OTP verified successfully!')),
//         );
        
//         // Navigate to the next screen (update this with your desired screen)
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => SplashScreen()), // Replace SplashScreen with the screen you want to navigate to
//         );
//       } else {
//         // Show error if OTP is incorrect
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Incorrect OTP. Please try again.')),
//         );
//       }
//     } on AppwriteException catch (e) {
//       // Handle any errors (e.g., invalid OTP, etc.)
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.message}')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue,
//         title: Text('OTP Verification'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'Enter the OTP sent to your email',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   controller: _otpController,
//                   keyboardType: TextInputType.number,
//                   maxLength: 6,
//                   decoration: InputDecoration(
//                     labelText: 'OTP',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter the OTP';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 _isLoading
//                     ? CircularProgressIndicator()
//                     : ElevatedButton(
//                         onPressed: _verifyOtp,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           shape: StadiumBorder(),
//                           padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
//                         ),
//                         child: Text(
//                           'Verify OTP',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

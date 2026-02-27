// import 'package:flutter/material.dart';
// import 'package:projectqdel/core/constants/color_constants.dart';
// import 'package:projectqdel/model/user_models.dart';
// import 'package:projectqdel/services/api_service.dart';
// import 'package:projectqdel/view/splash_screen.dart';
// import 'package:projectqdel/view/usertype_screen.dart';

// class CarrierProfile extends StatefulWidget {
//   const CarrierProfile({super.key});

//   @override
//   State<CarrierProfile> createState() => _CarrierProfileState();
// }

// class _CarrierProfileState extends State<CarrierProfile> {
//   final ApiService apiService = ApiService();
//   bool isCarrier = false;
//   bool switchingRole = false;

//   UserModel? user;
//   bool loading = true;
//   final _firstNameCtrl = TextEditingController();
//   final _lastNameCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();

//   bool updating = false;

//   @override
//   void initState() {
//     super.initState();
//     loadProfile();
//   }

//   @override
//   void dispose() {
//     _firstNameCtrl.dispose();
//     _lastNameCtrl.dispose();
//     _emailCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> loadProfile() async {
//     final api = ApiService();
//     user = await api.getMyProfile();

//     isCarrier = user?.userType == "carrier";

//     setState(() => loading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (user == null) {
//       return const Scaffold(
//         body: Center(child: Text("Failed to load profile")),
//       );
//     }
//     return Scaffold(
//       backgroundColor: const Color(0xffF6F7F9),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   _header(context),
//                   const SizedBox(height: 60),
//                   _profileInfo(),
//                   const SizedBox(height: 20),
//                   _personalDetailsCard(),
//                   const SizedBox(height: 20),
//                   _logoutCard(),
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _actionBtn(String text, Color color, VoidCallback onTap) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       onPressed: onTap,
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _header(BuildContext context) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Container(
//           height: 150,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xffE53935), Color(0xffF0625F)],
//             ),
//             borderRadius: BorderRadius.only(
//               bottomLeft: Radius.circular(40),
//               bottomRight: Radius.circular(40),
//             ),
//           ),
//         ),

//         Positioned(
//           top: 45,
//           left: 16,
//           child: _circleButton(
//             Icons.arrow_back_ios_new,
//             () => Navigator.pop(context),
//           ),
//         ),
//         Positioned(
//           top: 45,
//           right: 16,
//           child: _circleButton(Icons.more_horiz, () {}),
//         ),
//         const Positioned(
//           top: 48,
//           left: 0,
//           right: 0,
//           child: Center(
//             child: Text(
//               "Profile Details",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),

//         Positioned(
//           bottom: -50,
//           left: 0,
//           right: 0,
//           child: Center(
//             child: Stack(
//               children: [
//                 Container(
//                   height: 100,
//                   width: 100,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 4),
//                     color: Colors.orange.shade100,
//                   ),
//                   child: const Icon(Icons.person, size: 50),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _circleButton(IconData icon, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 38,
//         width: 38,
//         decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
//         child: Icon(icon, color: Colors.red, size: 18),
//       ),
//     );
//   }

//   Widget _profileInfo() {
//     return Column(
//       children: [
//         Text(
//           "${user!.firstName} ${user!.lastName}".toUpperCase(),
//           style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }

//   Widget _personalDetailsCard() {
//     return _card(
//       title: "Personal Details",
//       leading: const Icon(Icons.person, color: Colors.red),
//       children: [
//         _divider(),
//         _infoRow(
//           Icons.badge,
//           "FULL NAME",
//           "${user!.firstName} ${user!.lastName}".toUpperCase(),
//         ),
//         _divider(),
//         _infoRow(Icons.email, "EMAIL ADDRESS", user!.email),
//         _divider(),
//         _infoRow(Icons.phone, "PHONE NUMBER", user!.phone),
//         const SizedBox(height: 12),
//         _divider(),

//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _actionBtn("Change User Type", Colors.red, () async {
//               await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => UsertypeScreen(currentUser: user!),
//                 ),
//               );
//               loadProfile();
//             }),
//             SizedBox(width: 20),
//             _actionBtn("Edit Profile", Colors.red, _openEditProfileDialog),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _textField(
//     String label,
//     TextEditingController controller, {
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//   }

//   void _openEditProfileDialog() {
//     _firstNameCtrl.text = user!.firstName;
//     _lastNameCtrl.text = user!.lastName;
//     _emailCtrl.text = user!.email;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) {
//         return SafeArea(
//           child: Padding(
//             padding: EdgeInsets.only(
//               left: 16,
//               right: 16,
//               top: 16,
//               bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//             ),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const Center(
//                     child: Text(
//                       "Edit Profile",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   _textField("First Name", _firstNameCtrl),
//                   _textField("Last Name", _lastNameCtrl),
//                   _textField(
//                     "Email",
//                     _emailCtrl,
//                     keyboardType: TextInputType.emailAddress,
//                   ),

//                   const SizedBox(height: 24),

//                   updating
//                       ? const Center(child: CircularProgressIndicator())
//                       : _actionBtn(
//                           "Save Changes",
//                           Colors.green,
//                           _updateProfile,
//                         ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _logoutCard() {
//     return _card(
//       title: "Account",
//       leading: const Icon(Icons.logout, color: Colors.red),
//       children: [
//         Text(
//           "Ending your session will require you to log in again.",
//           style: TextStyle(color: ColorConstants.darkgrey),
//         ),
//         _divider(),

//         _actionBtn("Log Out", Colors.red, _confirmLogout),
//       ],
//     );
//   }

//   void _confirmLogout() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Logout"),
//         content: const Text("Are you sure you want to log out?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);

//               await ApiService.logout();

//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(builder: (_) => const SplashScreen()),
//                 (route) => false,
//               );
//             },
//             child: const Text("Logout", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _updateProfile() async {
//     setState(() => updating = true);

//     final success = await apiService.updateMyProfile(
//       firstName: _firstNameCtrl.text.trim(),
//       lastName: _lastNameCtrl.text.trim(),
//       email: _emailCtrl.text.trim(),
//     );

//     setState(() => updating = false);

//     if (success) {
//       setState(() {
//         user = user!.copyWith(
//           firstName: _firstNameCtrl.text.trim(),
//           lastName: _lastNameCtrl.text.trim(),
//           email: _emailCtrl.text.trim(),
//         );
//       });
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Profile updated successfully")),
//       );
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
//     }
//   }

//   Widget _card({
//     required String title,
//     Widget? leading,

//     required List<Widget> children,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: BoxBorder.all(color: Colors.red),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               if (leading != null) leading,
//               if (leading != null) const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Spacer(),
//             ],
//           ),
//           const SizedBox(height: 12),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _infoRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.grey),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _divider() {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       height: 1,
//       width: double.infinity,
//       color: Colors.grey.shade300,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/view_allOrders.dart';
import 'package:projectqdel/view/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();
  await ApiService.loadUserData();
  await ApiService.loadSession();
  runApp(Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SplashScreen(), debugShowCheckedModeBanner: false);
  }
}

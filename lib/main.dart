import 'package:campus_catalogue/add_item.dart';
import 'package:campus_catalogue/screens/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:campus_catalogue/screens/splash_screen.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:campus_catalogue/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với cấu hình từ firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey =
      "pk_test_51MZHMhSF3jyzuIge766JvDB1tCbBuUk5F1NjHLW66gy4aPeZZxWe6q3CVTmOO1m50N5sEdSfrj7Vrcr5O2EZs4tA00QvS9CKQ6";

  // Tải biến môi trường từ file .env
  // await dotenv.load(fileName: "assets/.env");

  // Gọi hàm fetch_categories nếu cần
  // fetch_categories();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'campus_catalogue',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Đặt màu nền trắng
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Đặt màu nền của AppBar là trắng
          elevation: 0, // Loại bỏ bóng (shadow) của AppBar nếu cần
          // iconTheme: IconThemeData(color: Colors.black), // Đặt màu của các icon trên AppBar
          // titleTextStyle: TextStyle(color: Colors.black, fontSize: 20), // Đặt màu cho tiêu đề
        ),
      ),
      routes: {
        // '/': (context) => SplashScreen(),
        '/': (context) => const LoginScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/user_provider.dart';
import 'providers/favorite_provider.dart';
import './providers/notification_provider.dart';

void main() async {
  // 1. Đảm bảo Flutter Binding đã sẵn sàng trước khi gọi code Native
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo Firebase
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProxyProvider<UserProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, userProvider, notificationProvider) {
            final userId = userProvider.currentUserId?.toString();
            notificationProvider!..updateUserId(userId);
            return notificationProvider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MANB SHOP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}
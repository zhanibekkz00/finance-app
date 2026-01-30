import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'repositories/database_helper.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable offline persistence for Web correctly
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  try {
    // Initialize Database (skip on web - sqflite doesn't support web)
    if (!kIsWeb) {
      await DatabaseHelper.instance.database;
    } else {
      debugPrint('Database initialization skipped on web platform');
    }
  } catch (e) {
    debugPrint('Database initialization error: $e');
    // Continue anyway - database will be initialized lazily when needed
  }

  try {
    // Initialize Notifications
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification initialization error: $e');
    // Continue anyway - notifications are optional
  }

  runApp(
    const ProviderScope(
      child: AppRoot(),
    ),
  );
}

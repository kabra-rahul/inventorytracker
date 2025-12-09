//main.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set Firestore settings: Enable cache (persistence) — new way
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Inventory Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: router,

      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final isDesktop = !kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

      /*  return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              child: child,
            ),
          ),
        );*/
        Widget wrapped = child;

        if (isDesktop) {
          // Desktop → center & constrain width
          wrapped = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: child,
            ),
          );
        } else {
          // Mobile & Web → SafeArea
          wrapped = SafeArea(child: child);
        }

        if (isDesktop) {
          return Scrollbar(
            thickness: 15.0,
            // Use PrimaryScrollController to handle the main app scrolling
            child: wrapped,
          );
        }
        return wrapped;
      },
    );
  }
}
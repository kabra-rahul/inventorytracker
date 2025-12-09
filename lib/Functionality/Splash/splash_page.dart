//splash.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/routes/app_router.dart';
import 'package:inventorytracker/Provider/auth_provider.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';


class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          Future.microtask(() {
            if (context.mounted) { // Check context.mounted before using it
              context.go(AppRoutePaths.login);
            }
          });
          return const _SplashAnimation();
        }
        // Wait for AppStoreProvider to load
        return  ref.watch(appStoreProvider).when(
          data: (store)  {
            Future.microtask(() {
              if (context.mounted) {
                context.go(AppRoutePaths.dashboard);
              }
            });
            return const _SplashAnimation();
          },
          loading: () => _SplashAnimation(),
          error: (err, stack) => _SplashAnimation(),
        );
      },
      loading: () => _SplashAnimation(),
      error: (err, StackTrace stack) => _SplashAnimation(),
    );
  }
}

/*
  @override
  Widget build(BuildContext context) {

    // The build method only handles the UI (the splash animation)
    return const _SplashAnimation();
  }
}
*/
class _SplashAnimation extends StatefulWidget {
  const _SplashAnimation();

  @override
  State<_SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<_SplashAnimation> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/logo.png", width: 200, height: 200),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              // This indicator stays visible until the AWAIT finishes.
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
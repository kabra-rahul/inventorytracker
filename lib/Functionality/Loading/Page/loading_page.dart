

import 'package:flutter/material.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';


class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: SizeConstants.spaceBetweenFields),
            Text('Loading your data...')
          ],
        ),
      ),
    );
  }
}
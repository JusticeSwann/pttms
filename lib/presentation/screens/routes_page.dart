// lib/presentation/screens/routes_page.dart

import 'package:flutter/material.dart';
import 'package:pttms/presentation/widgets/routes_selection_widget.dart';

class RoutesPage extends StatelessWidget {
  const RoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF424242), // Dark grey background
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 30),
            Center(
              child: RoutesSelectionWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

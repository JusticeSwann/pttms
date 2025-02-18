import 'package:flutter/material.dart';
import 'package:pttms/presentation/widgets/routes_selection_widget.dart';

class RoutesPage extends StatelessWidget {
  const RoutesPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Column(
              children: [
                SizedBox(height: 30,),
                Center(
                  child: RoutesSelectionWidget()
                )
              ],
            )
          ],
        ),
      )
    );
  }
}
import 'package:flutter/material.dart';

class ApplePage extends StatelessWidget {
  const ApplePage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final fruitName = name.toLowerCase();
    final imagePath = fruitName == 'orange'
        ? 'assets/images/orange.png'
        : 'assets/images/apple.jpg';

    return Scaffold(
      appBar: AppBar(
        title: Text(fruitName[0].toUpperCase() + fruitName.substring(1)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 100, backgroundImage: AssetImage(imagePath)),
            const SizedBox(height: 20),
            Text(
              fruitName[0].toUpperCase() + fruitName.substring(1),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

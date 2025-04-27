import 'package:flutter/material.dart';

class SaleScreen extends StatelessWidget {
  const SaleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Screen'),
      ),
      body: const Center(
        child: Text('Welcome to the Sale Screen!'),
      ),
    );
  }
}

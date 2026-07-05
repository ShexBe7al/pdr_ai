import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PDR AI",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.car_repair,
                size: 100,
                color: Colors.blue,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {},
                child: const Text("Live Scan"),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () {},
                child: const Text("Gallery"),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () {},
                child: const Text("Reports"),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () {},
                child: const Text("Settings"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
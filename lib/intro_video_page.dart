import 'dart:async';
import 'package:flutter/material.dart';

class IntroVideoPage extends StatefulWidget {
  @override
  _IntroVideoPageState createState() => _IntroVideoPageState();
}

class _IntroVideoPageState extends State<IntroVideoPage> with TickerProviderStateMixin {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();

    // Simula il caricamento
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        progress += 0.02;
        if (progress >= 1.0) {
          timer.cancel();
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Sfondo
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background_parchment.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Logo e titolo centrati in alto
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo_giostra.png',
                    height: 140,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Quiz di Giostra",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[900],
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 6,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cavallo che segue il progresso
          Positioned(
            bottom: 120,
            left: screenWidth * progress - 50, // 50 per centrare il cavallo
            child: Image.asset(
              'assets/horse.png',
              height: 100,
            ),
          ),

          // Barra di caricamento e testo
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.brown[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[800]!),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Preparati a giostrare...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Pulsante "Salta"
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.4),
                  ),
                  child: Text("Salta", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

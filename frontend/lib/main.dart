import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bloc/game_bloc.dart';
import 'networking/api/game_api.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyrics Guesser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B3DF2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
      ),
      home: const HomeScreen(),
      routes: {
        '/game': (_) => BlocProvider(
              create: (context) =>
                  GameBloc(GameApi())..add(GameStarted()),
              child: const GameScreen(),
            ),
      },
    );
  }
}

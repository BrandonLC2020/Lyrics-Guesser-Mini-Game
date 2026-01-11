import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';
import '../models/game_mode.dart';
import '../networking/api/game_api.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.background,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: _GlowOrb(
                  size: 220,
                  color: palette.orbTop,
                ),
              ),
              Positioned(
                bottom: -90,
                left: -70,
                child: _GlowOrb(
                  size: 240,
                  color: palette.orbBottom,
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 720;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lyrics Guesser',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 44,
                                color: palette.title,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pick a mode. Raise the stakes. Guess the music.',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                color: palette.subtitle,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Expanded(
                              child: isWide
                                  ? Row(
                                      children: _buildCards(
                                        context,
                                        palette,
                                        axis: Axis.horizontal,
                                      ),
                                    )
                                  : ListView(
                                      children: _buildCards(
                                        context,
                                        palette,
                                        axis: Axis.vertical,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCards(
    BuildContext context,
    _HomePalette palette, {
    required Axis axis,
  }) {
    final cards = [
      _ModeCard(
        mode: GameMode.artist,
        title: 'Guess the Artist',
        description: 'Masked lyrics. Pure intuition.',
        icon: Icons.mic_external_on,
        accent: palette.artistAccent,
      ),
      _ModeCard(
        mode: GameMode.track,
        title: 'Guess the Track',
        description: 'Find the title hiding in the lines.',
        icon: Icons.album_outlined,
        accent: palette.trackAccent,
      ),
      _ModeCard(
        mode: GameMode.lyrics,
        title: 'Fill the Lyrics',
        description: 'Patch the missing words live.',
        icon: Icons.edit_note,
        accent: palette.lyricsAccent,
      ),
    ];

    return cards.map((card) {
      final content = card.build(
        context,
        palette,
        onTap: () => _selectDifficulty(context, card.mode),
      );
      final padded = Padding(
        padding: EdgeInsets.only(
          right: axis == Axis.horizontal ? 16 : 0,
          bottom: axis == Axis.vertical ? 16 : 0,
        ),
        child: content,
      );
      if (axis == Axis.horizontal) {
        return Expanded(child: padded);
      }
      return padded;
    }).toList();
  }

  Future<void> _selectDifficulty(BuildContext context, GameMode mode) async {
    final palette = _HomePalette();
    final selection = await showModalBottomSheet<GameDifficulty>(
      context: context,
      backgroundColor: palette.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select difficulty',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 26,
                color: palette.title,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Easy keeps the lyrics clearer. Hard hides more.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: palette.subtitle,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DifficultyButton(
                    label: 'Easy',
                    icon: Icons.wb_sunny_outlined,
                    color: palette.easyAccent,
                    onTap: () => Navigator.pop(context, GameDifficulty.easy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DifficultyButton(
                    label: 'Hard',
                    icon: Icons.bolt_outlined,
                    color: palette.hardAccent,
                    onTap: () => Navigator.pop(context, GameDifficulty.hard),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (selection != null && context.mounted) {
      _startGame(context, mode, selection);
    }
  }

  void _startGame(
    BuildContext context,
    GameMode mode,
    GameDifficulty difficulty,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GameBloc(
            GameApi(),
            initialMode: mode,
            initialDifficulty: difficulty,
          )
            ..add(
              GameModeSelected(
                mode: mode,
                difficulty: difficulty,
              ),
            )
            ..add(GameStarted()),
          child: const GameScreen(),
        ),
      ),
    );
  }
}

class _ModeCard {
  final GameMode mode;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  _ModeCard({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  Widget build(
    BuildContext context,
    _HomePalette palette, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accent.withOpacity(0.2),
                  child: Icon(icon, color: accent, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    color: palette.title,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: palette.subtitle,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'Tap to play',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: palette.ctaText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: palette.ctaText),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.55),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

class _HomePalette {
  final List<Color> background = [
    const Color(0xFFFDEBD0),
    const Color(0xFFE6F7F1),
    const Color(0xFFE4ECFF),
  ];
  final Color title = const Color(0xFF2A2A2A);
  final Color subtitle = const Color(0xFF4F4F4F);
  final Color cardBackground = Colors.white.withOpacity(0.92);
  final Color sheetBackground = const Color(0xFFF9F3E7);
  final Color ctaText = const Color(0xFF1F4ED8);
  final Color artistAccent = const Color(0xFF6B3DF2);
  final Color trackAccent = const Color(0xFF0F9D8C);
  final Color lyricsAccent = const Color(0xFFE4692A);
  final Color easyAccent = const Color(0xFFFFD166);
  final Color hardAccent = const Color(0xFFFF8C6B);
  final Color orbTop = const Color(0xFF9AD0FF);
  final Color orbBottom = const Color(0xFFFFB997);
}

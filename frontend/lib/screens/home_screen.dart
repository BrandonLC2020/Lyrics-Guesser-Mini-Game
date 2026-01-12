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
                  final titleSize = isWide ? 44.0 : 32.0;
                  final subtitleSize = isWide ? 18.0 : 16.0;
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
                                fontSize: titleSize,
                                color: palette.title,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pick a mode. Raise the stakes. Guess the music.',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: subtitleSize,
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
                                        compact: false,
                                        addPadding: true,
                                        wrapExpanded: true,
                                      ),
                                    )
                                  : CustomScrollView(
                                      slivers: [
                                        SliverGrid(
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 0.78,
                                          ),
                                          delegate:
                                              SliverChildListDelegate.fixed(
                                            _buildCards(
                                              context,
                                              palette,
                                              compact: true,
                                              addPadding: false,
                                              wrapExpanded: false,
                                            ),
                                          ),
                                        ),
                                      ],
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
    required bool compact,
    required bool addPadding,
    required bool wrapExpanded,
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
      _ModeCard(
        mode: GameMode.shuffle,
        title: 'Shuffle Play',
        description: 'Random modes. Random challenges.',
        icon: Icons.shuffle,
        accent: palette.shuffleAccent,
      ),
    ];

    return cards.map((card) {
      final content = card.build(
        context,
        palette,
        onTap: () => _selectDifficulty(context, card.mode),
        compact: compact,
      );
      final padded = addPadding
          ? Padding(padding: const EdgeInsets.only(right: 16), child: content)
          : content;
      return wrapExpanded ? Expanded(child: padded) : padded;
    }).toList();
  }

  Future<void> _selectDifficulty(BuildContext context, GameMode mode) async {
    final palette = _HomePalette();
    final result = await showModalBottomSheet<_GameConfig>(
      context: context,
      backgroundColor: palette.sheetBackground,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DifficultySheet(palette: palette),
    );

    if (result != null && context.mounted) {
      _startGame(
        context,
        mode,
        result.difficulty,
        result.backgroundArtEnabled,
      );
    }
  }

  void _startGame(
    BuildContext context,
    GameMode mode,
    GameDifficulty difficulty,
    bool backgroundArtEnabled,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GameBloc(
            GameApi(),
            initialMode: mode,
            initialDifficulty: difficulty,
            backgroundArtEnabled: backgroundArtEnabled,
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

class _GameConfig {
  final GameDifficulty difficulty;
  final bool backgroundArtEnabled;
  _GameConfig(this.difficulty, this.backgroundArtEnabled);
}

class _DifficultySheet extends StatefulWidget {
  final _HomePalette palette;
  const _DifficultySheet({required this.palette});

  @override
  State<_DifficultySheet> createState() => _DifficultySheetState();
}

class _DifficultySheetState extends State<_DifficultySheet> {
  bool _backgroundArtEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select difficulty',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 26,
              color: widget.palette.title,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Easy keeps the lyrics clearer. Hard hides more. Random mixes it up.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: widget.palette.subtitle,
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            value: _backgroundArtEnabled,
            onChanged: (value) =>
                setState(() => _backgroundArtEnabled = value),
            title: Text(
              'Background art hint',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.palette.title,
              ),
            ),
            subtitle: Text(
              'Show blurred album art as a subtle clue.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: widget.palette.subtitle,
              ),
            ),
            activeColor: widget.palette.ctaText,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DifficultyButton(
                  label: 'Easy',
                  icon: Icons.wb_sunny_outlined,
                  color: widget.palette.easyAccent,
                  onTap: () => Navigator.pop(
                    context,
                    _GameConfig(GameDifficulty.easy, _backgroundArtEnabled),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DifficultyButton(
                  label: 'Hard',
                  icon: Icons.bolt_outlined,
                  color: widget.palette.hardAccent,
                  onTap: () => Navigator.pop(
                    context,
                    _GameConfig(GameDifficulty.hard, _backgroundArtEnabled),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DifficultyButton(
                  label: 'Random',
                  icon: Icons.casino_outlined,
                  color: widget.palette.randomAccent,
                  onTap: () => Navigator.pop(
                    context,
                    _GameConfig(GameDifficulty.random, _backgroundArtEnabled),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    bool compact = false,
  }) {
    final avatarRadius = compact ? 20.0 : 26.0;
    final iconSize = compact ? 22.0 : 28.0;
    final titleSize = compact ? 20.0 : 24.0;
    final descriptionSize = compact ? 14.0 : 16.0;
    final padding = compact ? 16.0 : 20.0;
    final ctaSize = compact ? 12.0 : 14.0;
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
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: accent.withOpacity(0.2),
                  child: Icon(icon, color: accent, size: iconSize),
                ),
                SizedBox(height: compact ? 12 : 16),
                Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: titleSize,
                    color: palette.title,
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Text(
                  description,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: descriptionSize,
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
                        fontSize: ctaSize,
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
  final Color shuffleAccent = const Color(0xFFEA4C89);
  final Color easyAccent = const Color(0xFFFFD166);
  final Color hardAccent = const Color(0xFFFF8C6B);
  final Color randomAccent = const Color(0xFF76B7FF);
  final Color orbTop = const Color(0xFF9AD0FF);
  final Color orbBottom = const Color(0xFFFFB997);
}

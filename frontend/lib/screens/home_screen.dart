import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/game_bloc.dart';
import '../models/game_mode.dart';
import '../networking/api/game_api.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: _GlowOrb(
                  size: 220,
                  color: AppTheme.accentTeal.withOpacity(0.3),
                ),
              ),
              Positioned(
                bottom: -90,
                left: -70,
                child: _GlowOrb(
                  size: 240,
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 720;
                  final titleSize = isWide ? 56.0 : 40.0;
                  final subtitleSize = isWide ? 20.0 : 16.0;
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
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: titleSize,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Pick a mode. Raise the stakes. Guess the music.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: subtitleSize,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isWide ? 1.6 : 0.8,
                                padding: EdgeInsets.zero,
                                children: _buildCards(
                                  context,
                                  compact: !isWide,
                                  addPadding: false,
                                  wrapExpanded: false,
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
    BuildContext context, {
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
        accent: AppTheme.primaryPurple,
      ),
      _ModeCard(
        mode: GameMode.track,
        title: 'Guess the Track',
        description: 'Find the title hiding in the lines.',
        icon: Icons.album_outlined,
        accent: AppTheme.accentTeal,
      ),
      _ModeCard(
        mode: GameMode.lyrics,
        title: 'Fill the Lyrics',
        description: 'Patch the missing words live.',
        icon: Icons.edit_note,
        accent: AppTheme.accentOrange,
      ),
      _ModeCard(
        mode: GameMode.shuffle,
        title: 'Shuffle Play',
        description: 'Random modes. Random challenges.',
        icon: Icons.shuffle,
        accent: AppTheme.accentPink,
      ),
    ];

    return cards.map((card) {
      final content = card.build(
        context,
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
    final theme = Theme.of(context);
    final result = await showModalBottomSheet<_GameConfig>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DifficultySheet(),
    );

    if (result != null && context.mounted) {
      _startGame(context, mode, result.difficulty, result.backgroundArtEnabled);
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
          create: (_) =>
              GameBloc(
                  GameApi(),
                  initialMode: mode,
                  initialDifficulty: difficulty,
                  backgroundArtEnabled: backgroundArtEnabled,
                )
                ..add(GameModeSelected(mode: mode, difficulty: difficulty))
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
  @override
  State<_DifficultySheet> createState() => _DifficultySheetState();
}

class _DifficultySheetState extends State<_DifficultySheet> {
  bool _backgroundArtEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select difficulty',
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Easy keeps the lyrics clearer. Hard hides more. Random mixes it up.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            value: _backgroundArtEnabled,
            onChanged: (value) => setState(() => _backgroundArtEnabled = value),
            title: Text(
              'Background art hint',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            subtitle: Text(
              'Show blurred album art as a subtle clue.',
              style: theme.textTheme.bodyMedium,
            ),
            activeColor: AppTheme.primaryPurple,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DifficultyButton(
                  label: 'Easy',
                  icon: Icons.wb_sunny_outlined,
                  color: AppTheme.accentTeal,
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
                  color: AppTheme.accentOrange,
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
                  color: AppTheme.accentBlue,
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
    BuildContext context, {
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final avatarRadius = compact ? 22.0 : 28.0;
    final iconSize = compact ? 24.0 : 32.0;
    final titleSize = compact ? 20.0 : 24.0;
    final descriptionSize = compact ? 14.0 : 16.0;
    final padding = compact ? 16.0 : 24.0;
    final ctaSize = compact ? 12.0 : 14.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
                  backgroundColor: accent.withOpacity(0.15),
                  child: Icon(icon, color: accent, size: iconSize),
                ),
                SizedBox(height: compact ? 12 : 20),
                Text(
                  title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: titleSize,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Text(
                  description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: descriptionSize,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'Tap to play',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: ctaSize,
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
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
      style:
          ElevatedButton.styleFrom(
            backgroundColor: color,
            // foregroundColor handled by theme or default
            // padding handled by theme
            // shape handled by theme
            // textStyle handled by theme
          ).copyWith(
            // Override specifically for difficulty buttons if they need unique colors
            backgroundColor: WidgetStateProperty.all(color),
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
        gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
      ),
    );
  }
}

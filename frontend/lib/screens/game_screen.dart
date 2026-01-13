import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/game_bloc.dart';
import '../models/game_mode.dart';
import '../networking/dto/new_round_response.dart';
import '../networking/dto/guess_result.dart';
import 'loading_view.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _lyricsRoundToken;
  final Map<String, String> _lyricsGuesses = {};
  final List<String> _blankKeys = [];
  int _selectedBlankIndex = -1;
  final TextEditingController _lyricsInputController = TextEditingController();
  final FocusNode _lyricsInputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _lyricsInputController.addListener(_handleLyricsInputChanged);
  }

  @override
  void dispose() {
    _lyricsInputController.removeListener(_handleLyricsInputChanged);
    _lyricsInputController.dispose();
    _lyricsInputFocus.dispose();
    super.dispose();
  }

  void _handleLyricsInputChanged() {
    if (_selectedBlankIndex < 0 || _selectedBlankIndex >= _blankKeys.length) {
      return;
    }
    final key = _blankKeys[_selectedBlankIndex];
    if (!mounted) return;
    setState(() {
      _lyricsGuesses[key] = _lyricsInputController.text;
    });
  }

  void _initLyricsRound(NewRoundResponse round) {
    _lyricsRoundToken = round.gameToken;
    _blankKeys
      ..clear()
      ..addAll(round.blanksMetadata.map((blank) => blank.key));
    _lyricsGuesses
      ..clear()
      ..addEntries(_blankKeys.map((key) => MapEntry(key, '')));
    _selectedBlankIndex = _blankKeys.isEmpty ? -1 : 0;
    _lyricsInputController.text = _selectedBlankIndex >= 0
        ? _lyricsGuesses[_blankKeys[_selectedBlankIndex]] ?? ''
        : '';
  }

  void _selectBlankByIndex(int index) {
    if (_blankKeys.isEmpty) return;
    final length = _blankKeys.length;
    final normalized = (index % length + length) % length;
    setState(() {
      _selectedBlankIndex = normalized;
      final key = _blankKeys[_selectedBlankIndex];
      _lyricsInputController.text = _lyricsGuesses[key] ?? '';
      _lyricsInputController.selection = TextSelection.collapsed(
        offset: _lyricsInputController.text.length,
      );
    });
    _lyricsInputFocus.requestFocus();
  }

  List<String> _collectLyricsGuesses(NewRoundResponse round) {
    return round.blanksMetadata
        .map((blank) => _lyricsGuesses[blank.key]?.trim() ?? '')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is GameLoaded) {
          final mode = parseGameMode(state.round.roundType);
          if (mode == GameMode.lyrics &&
              state.round.gameToken != _lyricsRoundToken) {
            if (!mounted) return;
            setState(() => _initLyricsRound(state.round));
          }
        }
        if (state is GameGuessSubmitted) {
          if (state.result.isCorrect) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.heavyImpact();
          }
        }
      },
      builder: (context, state) {
        String? backgroundUrl;
        if (state is GameLoaded) {
          backgroundUrl = state.round.albumCoverUrl;
        } else if (state is GameGuessSubmitted) {
          backgroundUrl = state.round.albumCoverUrl;
        }
        final showBackgroundArt = state.backgroundArtEnabled &&
            backgroundUrl != null &&
            backgroundUrl.isNotEmpty;
        final mediaQuery = MediaQuery.of(context);
        final isMobile = mediaQuery.size.width < 600;

        Widget? bottomSheet;
        if (state is GameLoaded) {
          final mode = parseGameMode(state.round.roundType);
          if (mode != GameMode.lyrics && isMobile) {
            bottomSheet = _GuessInputBar(
              prompt: mode == GameMode.track
                  ? 'What is the track title?'
                  : 'Who is the artist?',
              hint: mode == GameMode.track
                  ? 'Enter track title...'
                  : 'Enter artist name...',
              onSubmit: (guess) =>
                  context.read<GameBloc>().add(GuessSubmitted(guess)),
            );
          } else if (mode == GameMode.lyrics && _blankKeys.isNotEmpty) {
            bottomSheet = _LyricsInputToolbar(
              controller: _lyricsInputController,
              focusNode: _lyricsInputFocus,
              selectedIndex: _selectedBlankIndex,
              total: _blankKeys.length,
              onPrev: () => _selectBlankByIndex(_selectedBlankIndex - 1),
              onNext: () => _selectBlankByIndex(_selectedBlankIndex + 1),
              onSubmit: () {
                HapticFeedback.lightImpact();
                context
                    .read<GameBloc>()
                    .add(GuessSubmitted(_collectLyricsGuesses(state.round)));
              },
            );
          }
        }

        return Scaffold(
          resizeToAvoidBottomInset: true,
          bottomSheet: bottomSheet,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                ),
              ),
              if (showBackgroundArt) ...[
                Image.network(
                  backgroundUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ],
              SafeArea(
                child: _buildContent(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, GameState state) {
    if (state is GameLoading &&
        (state is! GameLoaded && state is! GameGuessSubmitted)) {
      return LoadingView(
        status: _loadingStatus(
          state.selectedMode,
          state.selectedDifficulty,
        ),
      );
    }

    if (state is GameLoaded) {
      return _buildGameView(context, state.round);
    }

    if (state is GameGuessSubmitted) {
      return _buildResultView(
        context,
        state.result,
        state.round,
      );
    }

    return LoadingView(
      status: _loadingStatus(
        state.selectedMode,
        state.selectedDifficulty,
      ),
    );
  }

  Widget _buildGameView(
    BuildContext context,
    NewRoundResponse round,
  ) {
    final mode = parseGameMode(round.roundType);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hintLabel = mode == GameMode.track
        ? 'Hint: Track title has ${round.hintLength} letters'
        : 'Hint: Artist name has ${round.hintLength} letters';
    final leftCard = mode == GameMode.lyrics
        ? _LyricsFillCard(
            round: round,
            guesses: _lyricsGuesses,
            selectedKey: _selectedBlankIndex >= 0 &&
                    _selectedBlankIndex < _blankKeys.length
                ? _blankKeys[_selectedBlankIndex]
                : null,
            onSelectBlank: (index) => _selectBlankByIndex(index),
          )
        : _LyricsCard(lyrics: round.maskedLyrics);

    final wideSideWidgets = <Widget>[
      const SizedBox(height: 24),
      if (mode != GameMode.lyrics) _Hint(text: hintLabel),
      if (mode != GameMode.lyrics) const SizedBox(height: 24),
      if (mode != GameMode.lyrics)
        _GuessInputSection(
          prompt: mode == GameMode.track
              ? 'What is the track title?'
              : 'Who is the artist?',
          hint: mode == GameMode.track
              ? 'Enter track title...'
              : 'Enter artist name...',
          onSubmit: (guess) =>
              context.read<GameBloc>().add(GuessSubmitted(guess)),
        ),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: () => context.read<GameBloc>().add(const GameGiveUp()),
        icon: const Icon(Icons.help_outline),
        label: const Text("I don't know"),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ];

    final compactSideWidgets = <Widget>[
      const SizedBox(height: 24),
      if (mode != GameMode.lyrics) _Hint(text: hintLabel),
      if (mode != GameMode.lyrics) const SizedBox(height: 16),
      TextButton.icon(
        onPressed: () => context.read<GameBloc>().add(const GameGiveUp()),
        icon: const Icon(Icons.help_outline),
        label: const Text("I don't know"),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ];

    final needsBottomPadding =
        (mode != GameMode.lyrics && isMobile) ||
            (mode == GameMode.lyrics && _blankKeys.isNotEmpty);

    return _buildResponsiveLayout(
      context,
      header: const _Header(),
      leftCard: leftCard,
      sideWidgets: wideSideWidgets,
      compactSideWidgets: compactSideWidgets,
      bottomPadding: needsBottomPadding ? 160 : null,
    );
  }

  Widget _buildResultView(
    BuildContext context,
    GuessResult result,
    NewRoundResponse round,
  ) {
    final mode = parseGameMode(result.roundType);
    final leftCard = _LyricsCard(lyrics: round.maskedLyrics);
    final sideWidgets = <Widget>[
      const SizedBox(height: 24),
      _ResultCard(result: result, mode: mode),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => context.read<GameBloc>().add(NewRoundStarted()),
        icon: const Icon(Icons.refresh),
        label: const Text('New Round'),
      ),
    ];

    return _buildResponsiveLayout(
      context,
      header: const _Header(),
      leftCard: leftCard,
      sideWidgets: sideWidgets,
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context, {
    required Widget header,
    required Widget leftCard,
    required List<Widget> sideWidgets,
    List<Widget>? compactSideWidgets,
    double? bottomPadding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final effectiveSideWidgets =
            isWide ? sideWidgets : (compactSideWidgets ?? sideWidgets);
        final content = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: leftCard,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          ...effectiveSideWidgets,
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  bottomPadding ?? 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 24),
                    leftCard,
                    ...effectiveSideWidgets,
                  ],
                ),
              );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: content,
          ),
        );
      },
    );
  }

  String _loadingStatus(GameMode mode, GameDifficulty difficulty) {
    if (mode == GameMode.shuffle) {
      return difficulty == GameDifficulty.hard
          ? 'Shuffling a tougher mix...'
          : difficulty == GameDifficulty.random
              ? 'Rolling the shuffle...'
              : 'Shuffling the mix...';
    }
    if (mode == GameMode.lyrics) {
      return difficulty == GameDifficulty.hard
          ? 'Obscuring the lyrics...'
          : difficulty == GameDifficulty.random
              ? 'Rolling the lyric blanks...'
              : 'Warming up the lyric sheet...';
    }
    if (mode == GameMode.track) {
      return difficulty == GameDifficulty.hard
          ? 'Scrambling track hints...'
          : difficulty == GameDifficulty.random
              ? 'Rolling the track clues...'
              : 'Finding the track...';
    }
    return difficulty == GameDifficulty.hard
        ? 'Masking the artist trail...'
        : difficulty == GameDifficulty.random
            ? 'Rolling the artist trail...'
        : 'Finding the artist...';
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    return Text(
      '🎵 Lyrics Guesser 🎵',
      textAlign: TextAlign.center,
      style: theme.textTheme.displayLarge?.copyWith(
        fontSize: isMobile ? 30 : 36,
        shadows: [
          const Shadow(
            blurRadius: 10.0,
            color: Colors.black26,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );
  }
}

class _LyricsCard extends StatelessWidget {
  final String lyrics;
  const _LyricsCard({required this.lyrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: AppTheme.primaryPurple,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lyrics',
                  style: theme.textTheme.headlineSmall?.copyWith(
                     color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              lyrics,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                height: 1.6,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: AppTheme.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuessInputSection extends StatefulWidget {
  final String prompt;
  final String hint;
  final ValueChanged<String> onSubmit;

  const _GuessInputSection({
    required this.prompt,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<_GuessInputSection> createState() => _GuessInputSectionState();
}

class _GuessInputSectionState extends State<_GuessInputSection> {
  final TextEditingController _guessController = TextEditingController();

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  void _submitGuess() {
    if (_guessController.text.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onSubmit(_guessController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.prompt,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _guessController,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryPurple.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white24,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryPurple,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.black12,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: theme.textTheme.bodyLarge,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submitGuess(),
            ),
            const SizedBox(height: 16),
            BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                final isLoading = state is GameLoading;
                return ElevatedButton(
                  onPressed: isLoading ? null : _submitGuess,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Guess',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final GuessResult result;
  final GameMode mode;
  const _ResultCard({required this.result, required this.mode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.isCorrect ? AppTheme.success : AppTheme.error;
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              result.isCorrect ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              result.message,
              style: theme.textTheme.displayMedium?.copyWith(
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (mode == GameMode.lyrics)
              Column(
                children: [
                  Text(
                    'Correct words:',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: result.correctWords
                        .map(
                          (word) => Chip(
                            label: Text(
                              word,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            backgroundColor: Colors.white,
                          ),
                        )
                        .toList(),
                  ),
                ],
              )
            else
              Text(
                'Correct answer: ${mode == GameMode.track ? result.correctTitle : result.correctArtist}',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Text(
              'Match score: ${result.matchScore}%',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LyricsFillCard extends StatefulWidget {
  final NewRoundResponse round;
  final Map<String, String> guesses;
  final String? selectedKey;
  final ValueChanged<int> onSelectBlank;

  const _LyricsFillCard({
    required this.round,
    required this.guesses,
    required this.selectedKey,
    required this.onSelectBlank,
  });

  @override
  State<_LyricsFillCard> createState() => _LyricsFillCardState();
}

class _LyricsFillCardState extends State<_LyricsFillCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = _parseLyrics(widget.round.maskedLyrics);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: AppTheme.accentOrange, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Fill the Blanks',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 4,
              runSpacing: 8,
              children: parts.map((part) {
                if (part.isBlank) {
                  final isSelected = part.key == widget.selectedKey;
                  final hasGuess = widget.guesses[part.key]?.isNotEmpty == true;
                  return GestureDetector(
                    onTap: () {
                      final index = widget.round.blanksMetadata
                          .indexWhere((b) => b.key == part.key);
                      if (index != -1) {
                        widget.onSelectBlank(index);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentOrange.withOpacity(0.3)
                            : hasGuess
                                ? AppTheme.primaryPurple.withOpacity(0.2)
                                : Colors.white10,
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? AppTheme.accentOrange
                                : hasGuess
                                    ? AppTheme.primaryPurple
                                    : Colors.white30,
                            width: 2,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasGuess ? widget.guesses[part.key]! : '_____',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: hasGuess ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return Text(
                  part.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                     fontSize: 18,
                     height: 1.6,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<_LyricsPart> _parseLyrics(String text) {
    final parts = <_LyricsPart>[];
    final pattern = RegExp(r'\[BLANK_(\d+)\]');
    int cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        parts.add(_LyricsPart(
          text: text.substring(cursor, match.start),
          isBlank: false,
          key: '',
        ));
      }

      final key = 'BLANK_${match.group(1)}';
      parts.add(_LyricsPart(
        text: '', // Placeholder text is handled in build
        isBlank: true,
        key: key,
      ));
      cursor = match.end;
    }

    if (cursor < text.length) {
      parts.add(_LyricsPart(
        text: text.substring(cursor),
        isBlank: false,
        key: '',
      ));
    }
    
    return parts;
  }
}

class _LyricsPart {
  final String text;
  final bool isBlank;
  final String key;
  _LyricsPart({required this.text, required this.isBlank, required this.key});
}

class _GuessInputBar extends StatefulWidget {
  final String prompt;
  final String hint;
  final ValueChanged<String> onSubmit;

  const _GuessInputBar({
    required this.prompt,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<_GuessInputBar> createState() => _GuessInputBarState();
}

class _GuessInputBarState extends State<_GuessInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16) + MediaQuery.of(context).viewInsets,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C), // Surface color
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black45)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
                widget.prompt,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 12),
             Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: _controller,
                     style: const TextStyle(color: Colors.white),
                     decoration: InputDecoration(
                       hintText: widget.hint,
                       hintStyle: const TextStyle(color: Colors.white38),
                       filled: true,
                       fillColor: Colors.white10,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(12),
                         borderSide: BorderSide.none,
                       ),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                     ),
                     onSubmitted: (value) {
                       if (value.trim().isNotEmpty) {
                         widget.onSubmit(value.trim());
                         _controller.clear();
                       }
                     },
                   ),
                 ),
                 const SizedBox(width: 12),
                 IconButton.filled(
                   onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                         widget.onSubmit(_controller.text.trim());
                         _controller.clear();
                      }
                   },
                   icon: const Icon(Icons.send_rounded),
                   style: IconButton.styleFrom(
                     backgroundColor: AppTheme.primaryPurple,
                     foregroundColor: Colors.white,
                   ),
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }
}

class _LyricsInputToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int selectedIndex;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _LyricsInputToolbar({
    required this.controller,
    required this.focusNode,
    required this.selectedIndex,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12) + MediaQuery.of(context).viewInsets,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
            Text(
              '${selectedIndex + 1} / $total',
              style: const TextStyle(color: Colors.white70, fontFeatures: [FontFeature.tabularFigures()]),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type word...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => onNext(),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSubmit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}


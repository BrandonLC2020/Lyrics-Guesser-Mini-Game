import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
              backgroundColor: Colors.red,
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade400,
                      Colors.blue.shade400,
                      Colors.pink.shade300,
                    ],
                  ),
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
                    color: Colors.black.withOpacity(0.3),
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
          backgroundColor: Colors.white.withOpacity(0.15),
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
          backgroundColor: Colors.white.withOpacity(0.15),
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
        label: const Text(
          'New Round',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.purple.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
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
    return Text(
      '🎵 Lyrics Guesser 🎵',
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSerifDisplay(
        fontSize: isMobile ? 30 : 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: Colors.purple.shade400,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lyrics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              lyrics,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                height: 1.6,
                color: Colors.black87,
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
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.prompt,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _guessController,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.purple.shade300, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.purple.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.spaceGrotesk(fontSize: 18),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submitGuess(),
            ),
            const SizedBox(height: 16),
            BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                final isLoading = state is GameLoading;
                return ElevatedButton(
                  onPressed: isLoading ? null : _submitGuess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: result.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: result.isCorrect
                ? Colors.green.shade300
                : Colors.red.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              result.isCorrect ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: result.isCorrect
                  ? Colors.green.shade600
                  : Colors.red.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              result.message,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: result.isCorrect
                    ? Colors.green.shade800
                    : Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (mode == GameMode.lyrics)
              Column(
                children: [
                  Text(
                    'Correct words:',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: result.correctWords
                        .map(
                          (word) => Chip(
                            label: Text(word),
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
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Text(
              'Match score: ${result.matchScore}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: Colors.black54,
              ),
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
    final blankLookup = {
      for (final blank in widget.round.blanksMetadata) blank.key: blank.length
    };
    final blankIndexLookup = {
      for (var i = 0; i < widget.round.blanksMetadata.length; i++)
        widget.round.blanksMetadata[i].key: i
    };
    final parts = <InlineSpan>[];
    final pattern = RegExp(r'\[BLANK_(\d+)\]');
    final text = widget.round.maskedLyrics;
    int cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        parts.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        );
      }

      final key = 'BLANK_${match.group(1)}';
      final length = blankLookup[key] ?? 6;
      final guess = widget.guesses[key] ?? '';
      final placeholderLength = length.clamp(3, 8).toInt();
      final placeholder = List.filled(placeholderLength, '_').join();
      final selected = widget.selectedKey == key;
      final index = blankIndexLookup[key] ?? -1;
      parts.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _LyricsBlankChip(
              label: guess.isEmpty ? placeholder : guess,
              selected: selected,
              onTap: index < 0 ? null : () => widget.onSelectBlank(index),
            ),
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < text.length) {
      parts.add(
        TextSpan(
          text: text.substring(cursor),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      );
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: Colors.orange.shade400,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fill the lyrics',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RichText(text: TextSpan(children: parts)),
            const SizedBox(height: 16),
            Text(
              'Tap a blank to fill it in.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, viewInsets + 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.prompt,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.purple.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.purple.shade400,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.spaceGrotesk(fontSize: 16),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BlocBuilder<GameBloc, GameState>(
                    builder: (context, state) {
                      final isLoading = state is GameLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Guess',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LyricsBlankChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _LyricsBlankChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.orange.shade400 : Colors.orange.shade100;
    final borderColor =
        selected ? Colors.orange.shade600 : Colors.orange.shade300;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
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
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final label = total == 0
        ? 'No blanks'
        : 'Blank ${selectedIndex + 1} of $total';
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, viewInsets + 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: total == 0 ? null : onPrev,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type missing lyric...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orange.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orange.shade400,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.spaceGrotesk(fontSize: 16),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ),
                  IconButton(
                    onPressed: total == 0 ? null : onNext,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<GameBloc, GameState>(
                    builder: (context, state) {
                      final isLoading = state is GameLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

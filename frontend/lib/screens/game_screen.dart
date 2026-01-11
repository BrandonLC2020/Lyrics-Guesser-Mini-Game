import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';
import '../models/game_mode.dart';
import '../networking/dto/new_round_response.dart';
import '../networking/dto/guess_result.dart';
import 'loading_view.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: BlocConsumer<GameBloc, GameState>(
            listener: (context, state) {
              if (state is GameError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameView(
    BuildContext context,
    NewRoundResponse round,
  ) {
    final mode = parseGameMode(round.roundType);
    final hintLabel = mode == GameMode.track
        ? 'Hint: Track title has ${round.hintLength} letters'
        : 'Hint: Artist name has ${round.hintLength} letters';
    final leftCard = mode == GameMode.lyrics
        ? _LyricsFillCard(
            round: round,
            onSubmit: (guesses) => context
                .read<GameBloc>()
                .add(GuessSubmitted(guesses)),
          )
        : _LyricsCard(lyrics: round.maskedLyrics);

    final sideWidgets = <Widget>[
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

    return _buildResponsiveLayout(
      context,
      header: const _Header(),
      leftCard: leftCard,
      sideWidgets: sideWidgets,
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
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
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
                          ...sideWidgets,
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 24),
                    leftCard,
                    ...sideWidgets,
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
    return Text(
      '🎵 Lyrics Guesser 🎵',
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSerifDisplay(
        fontSize: 36,
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
  final ValueChanged<List<String>> onSubmit;

  const _LyricsFillCard({
    required this.round,
    required this.onSubmit,
  });

  @override
  State<_LyricsFillCard> createState() => _LyricsFillCardState();
}

class _LyricsFillCardState extends State<_LyricsFillCard> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final blank in widget.round.blanksMetadata) {
      _controllers[blank.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> _collectGuesses() {
    return widget.round.blanksMetadata
        .map((blank) => _controllers[blank.key]?.text.trim() ?? '')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = widget.round.blanksMetadata.isNotEmpty;
    final blankLookup = {
      for (final blank in widget.round.blanksMetadata) blank.key: blank.length
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
      final controller = _controllers[key];
      final length = blankLookup[key] ?? 6;
      parts.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(
            width: 16.0 + length * 10,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(),
              ),
              style: GoogleFonts.spaceGrotesk(fontSize: 16),
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: canSubmit ? () => widget.onSubmit(_collectGuesses()) : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Submit Words'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

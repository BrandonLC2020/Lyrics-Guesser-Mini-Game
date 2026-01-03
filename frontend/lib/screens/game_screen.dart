import 'package:flutter/material.dart';
import '../networking/api/game_api.dart';
import '../networking/dto/new_round_response.dart';
import '../networking/dto/guess_result.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameApi _api = GameApi();
  final TextEditingController _guessController = TextEditingController();
  
  NewRoundResponse? _currentRound;
  GuessResult? _lastResult;
  bool _isLoading = false;
  bool _hasGuessed = false;

  @override
  void initState() {
    super.initState();
    _loadNewRound();
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _loadNewRound() async {
    setState(() {
      _isLoading = true;
      _hasGuessed = false;
      _lastResult = null;
      _guessController.clear();
    });

    try {
      final round = await _api.startNewRound();
      setState(() {
        _currentRound = round;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading round: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitGuess() async {
    if (_currentRound == null || _guessController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _api.submitGuess(
        _currentRound!.gameToken,
        _guessController.text.trim(),
      );
      setState(() {
        _lastResult = result;
        _hasGuessed = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting guess: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
          child: _isLoading && _currentRound == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      const Text(
                        '🎵 Lyrics Guesser 🎵',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                      ),
                      const SizedBox(height: 32),

                      // Lyrics Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                              if (_currentRound != null)
                                Text(
                                  _currentRound!.maskedLyrics,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hint
                      if (_currentRound != null && !_hasGuessed)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hint: Artist name has ${_currentRound!.hintLength} letters',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Guess Input
                      if (!_hasGuessed)
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Who is the artist?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _guessController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter artist name...',
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
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 18),
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _submitGuess,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _isLoading
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
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Result Display
                      if (_hasGuessed && _lastResult != null) ...[
                        const SizedBox(height: 24),
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _lastResult!.isCorrect
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _lastResult!.isCorrect
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _lastResult!.isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 64,
                                  color: _lastResult!.isCorrect
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _lastResult!.message,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: _lastResult!.isCorrect
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Correct answer: ${_lastResult!.correctArtist}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Match score: ${_lastResult!.matchScore}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadNewRound,
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}


import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:voicecare/screens/main_page.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with TickerProviderStateMixin {
  late ConversationClient _client;
  final List<Map<String, String>> _transcript = [];
  final ScrollController _scrollController = ScrollController();

  // Animation controllers for UI effects
  late AnimationController _pulseController;
  late AnimationController _waveController;

  static const Color primaryOrange = Color(0xFFDE9243);
  static const Color darkOrange = Color(0xFFC4561D);
  static const String customFont = 'GoogleSans';

  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _initializeClient();
    _requestPermissions();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  void _initializeClient() {
    _client = ConversationClient(
      callbacks: ConversationCallbacks(
        // Handles the initial connection to the ElevenLabs Agent
        onConnect: ({required conversationId}) =>
            debugPrint('✅ Connected: $conversationId'),

        // Logs when the session ends
        onDisconnect: (details) =>
            debugPrint('❌ Disconnected: ${details.reason}'),

        // Processes real-time words as the user speaks
        onTentativeUserTranscript: ({required transcript, required eventId}) =>
            _handleUserSpeech(transcript),

        // Processes final sentences once the user stops talking
        onUserTranscript: ({required transcript, required eventId}) =>
            _handleUserSpeech(transcript),

        // Handles incoming messages from Daniel (the Agent)
        onMessage: ({required message, required source}) {
          // Only add to the UI transcript if the message is from Daniel
          if (source.name.toLowerCase() != 'user') {
            setState(() {
              _transcript.add({'role': 'agent', 'text': message});
            });
            _scrollToBottom();
          }
        },

        // Updates UI based on conversation status (e.g., connected, disconnected)
        onStatusChange: ({required status}) => setState(() {}),

        // TRIGGER: Handles the "onboarding_complete" signal from the Agent
        onUnhandledClientToolCall: (ClientToolCall toolCall) async {
          debugPrint(
            '🤖 Daniel is triggering client tool: ${toolCall.toolName}',
          );

          if (toolCall.toolName == "onboarding_complete") {
            // 1. Give the agent a moment to finish its goodbye
            await Future.delayed(const Duration(seconds: 1));

            // 2. Safely end the voice session
            await _client.endSession();

            // 3. Move to the next screen
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            }
          }
        },

        // Error handling for session issues
        onError: (message, [context]) => debugPrint('❌ SDK Error: $message'),
      ),
    );

    // Add listener to rebuild UI for changes like Daniel starting/stopping speech
    _client.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _handleUserSpeech(String text) {
    if (text.isEmpty) return;
    setState(() {
      if (_transcript.isNotEmpty && _transcript.last['role'] == 'user') {
        _transcript.last['text'] = text;
      } else {
        _transcript.add({'role': 'user', 'text': text});
      }
    });
    _scrollToBottom();
  }

  Future<void> _handleStartStop() async {
    if (_client.status == ConversationStatus.connected) {
      await _client.endSession();
      return;
    }

    setState(() => _isStarting = true);

    // Your specific API Endpoint
    const String apiUrl = 'http://192.168.31.52:5000/api/voice-session';
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Uri uri = Uri.parse(data['signed_url']);
        await _client.startSession(agentId: uri.queryParameters['agent_id']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Voice',
              style: TextStyle(
                fontSize: 32,
                color: primaryOrange,
                fontWeight: FontWeight.w400,
                fontFamily: customFont,
              ),
            ),
            Text(
              'Care',
              style: TextStyle(
                fontSize: 32,
                color: darkOrange,
                fontWeight: FontWeight.w400,
                fontFamily: customFont,
              ),
            ),
          ],
        ),
        const Text(
          'Your digital friend, day and night.',
          style: TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 255, 255, 255),
            fontFamily: customFont,
            height: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _client.status == ConversationStatus.connected;
    final isSpeaking = _client.isSpeaking;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Image with Dark Gradient Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/autumn_bg.png', // Replace with your blurred background image
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              // Change this to .start to align Header, Greeting, and Transcript to the left
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Branding Header - Aligned Start
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                  child: _buildHeader(),
                ),

                const SizedBox(height: 20),

                // 3. Dynamic Center Piece (Greeting or Waveform) - Aligned Start
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: isConnected
                        ? _buildWaveform()
                        : Text(
                            "Hello, I'm\nGitanjali...",
                            textAlign: TextAlign
                                .start, // Ensures text alignment is left
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.1,
                              fontFamily: customFont,
                            ),
                          ),
                  ),
                ),

                // 4. Chat Transcript - Takes up available space
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 20,
                    ),
                    itemCount: _transcript.length,
                    itemBuilder: (context, index) {
                      final item = _transcript[index];
                      final isAi = item['role'] == 'agent';
                      return _buildChatLine(item['text']!, isAi);
                    },
                  ),
                ),

                // 5. Bottom Control Section - Centered explicitly
                Center(child: _buildBottomControls(isConnected, isSpeaking)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatLine(String text, bool isAi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isAi) _indicatorLine(),
          Flexible(
            child: Text(
              text,
              textAlign: isAi ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: isAi ? Colors.white.withOpacity(0.9) : Colors.white60,
                fontSize: 18,
                height: 1.4,
                fontFamily: customFont,
              ),
            ),
          ),
          if (!isAi) _indicatorLine(),
        ],
      ),
    );
  }

  Widget _indicatorLine() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      width: 1.5,
      height: 22,
      color: Colors.white38,
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 180, // Increased height for a bigger visual impact
      width: double.infinity,
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween will spread bars across width
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(60, (index) {
          // Increased to 60 bars to fill width
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              double baseHeight = 8.0; // Slightly thicker base

              // If speaking, use a more dynamic sine wave calculation
              double animationValue = _client.isSpeaking
                  ? _waveController.value
                  : 0.05;

              // Amplitude logic: making bars in the middle taller (Gaussian-ish distribution)
              double screenCenterFactor = (1 - ((index - 30).abs() / 30));

              double height =
                  baseHeight +
                  (math.sin(index * 0.5 + animationValue * 15) *
                          60 *
                          screenCenterFactor)
                      .abs();

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                width: 3, // Slightly wider bars for better visibility
                height: height,
                decoration: BoxDecoration(
                  // Use a slight gradient or opacity for that "glow" look
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (_client.isSpeaking)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildBottomControls(bool isConnected, bool isSpeaking) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isStarting
                ? null
                : _handleStartStop, // Disable tap while loading
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse effect (only if connected)
                if (isConnected)
                  ScaleTransition(
                    scale: Tween(
                      begin: 1.0,
                      end: 1.4,
                    ).animate(_pulseController),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                // Main Button Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isStarting ? primaryOrange : Colors.white24,
                      width: 1,
                    ),
                    color: Colors.black26,
                  ),
                  child: SizedBox(
                    width: 35,
                    height: 35,
                    child: _isStarting
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryOrange,
                            ),
                          )
                        : Icon(
                            isConnected
                                ? Icons.stop_rounded
                                : Icons.mic_none_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _isStarting
                ? "Connecting..."
                : (isConnected
                      ? (isSpeaking ? "Talking..." : "Listening...")
                      : "Tap to start"),
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 13,
              letterSpacing: 1,
              fontFamily: customFont,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _client.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

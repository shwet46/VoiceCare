import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> reminderData;
  const CallScreen({super.key, required this.reminderData});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late ConversationClient _client;
  // Local transcript to send to backend
  final List<Map<String, String>> _transcript = [];

  late AnimationController _pulseController;
  late AnimationController _waveController;
  bool _isStarting = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    _initializeClient();
    _requestPermissions();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartStop();
    });
  }

  void _initializeClient() {
    _client = ConversationClient(
      callbacks: ConversationCallbacks(
        onConnect: ({required conversationId}) =>
            debugPrint('✅ Connected: $conversationId'),
        onDisconnect: (details) async {
          // Trigger saving to backend when the call ends
          await _saveTranscriptToBackend();
        },
        onMessage: ({required message, required source}) {
          // Capture both User and Agent messages for a full call log
          final role = source.name.toLowerCase() == 'user'
              ? 'user'
              : 'assistant';
          setState(() {
            _transcript.add({
              'role': role,
              'text': message,
              'timestamp': DateTime.now().toIso8601String(),
            });
          });
        },
        onStatusChange: ({required status}) => setState(() {}),
        onUnhandledClientToolCall: (toolCall) async {
          // Handle specific end-of-call tools if defined in ElevenLabs dashboard
          // if (toolCall.toolName == "call_complete") {
          //   await Future.delayed(const Duration(seconds: 1));
          //   await _client.endSession();
          //   if (mounted) Navigator.pop(context);
          // }
        },
        onError: (msg, [ctx]) => debugPrint('❌ SDK Error: $msg'),
      ),
    );

    _client.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// Sends the collected transcript to your Python backend for analysis
  Future<void> _saveTranscriptToBackend() async {
    if (_transcript.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final String? baseUrl = dotenv.env['BACKEND_URL'];
    if (user == null) return;

    try {
      final response = await http.post(
        // Ensure this points to your specific save-transcript endpoint
        Uri.parse('$baseUrl/api/voice-session/save-transcript'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.uid,
          'agent_type': 'reminder', // Distinguishes from onboarding
          'call_id': _client.conversationId,
          'transcript': _transcript,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Call log saved successfully");
      }
    } catch (e) {
      debugPrint("❌ Error saving call log: $e");
    }
  }

  Future<void> _handleStartStop() async {
    if (_client.status == ConversationStatus.connected) {
      await _client.endSession();
      return;
    }

    final String? baseUrl = dotenv.env['BACKEND_URL'];

    setState(() => _isStarting = true);

    // Your specific API Endpoint
    String apiUrl = '$baseUrl/api/reminder-voice-session/start';
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

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    _client.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _client.status == ConversationStatus.connected;

    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/autumn_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildCallerHeader(isConnected),
                const Spacer(),
                if (isConnected) _buildWaveformSection(),
                const Spacer(),
                _buildLiveSubtitle(),
                const SizedBox(height: 30),
                _buildCallActions(isConnected),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallerHeader(bool isConnected) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isConnected)
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.25).animate(_pulseController),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            const CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white12,
              child: Icon(Icons.person, size: 85, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Gitanjali",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          !isConnected ? "VoiceCare Calling..." : "VoiceCare Audio Call",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildWaveformSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(45, (index) {
            return AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                double height =
                    5 +
                    (math.sin(index * 0.4 + _waveController.value * 12) *
                            50 *
                            (_client.isSpeaking ? 1 : 0.15))
                        .abs();
                return Container(
                  width: 4,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLiveSubtitle() {
    if (_transcript.isEmpty) return const SizedBox(height: 40);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        _transcript.last['text']!,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 18,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCallActions(bool isConnected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionIcon(
            Icons.volume_up,
            _isSpeakerOn,
            () => setState(() => _isSpeakerOn = !_isSpeakerOn),
          ),
          _actionIcon(Icons.videocam_off, false, null),
          _actionIcon(
            Icons.mic_off,
            _isMuted,
            () => setState(() => _isMuted = !_isMuted),
          ),
          GestureDetector(
            onTap: _isStarting ? null : _handleStartStop,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.redAccent : Colors.greenAccent,
              ),
              child: _isStarting
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isConnected ? Icons.call_end : Icons.call,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white : Colors.white10,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceAssistantService {
  // Use ConversationClient as defined in the 0.3.0 SDK
  late ConversationClient _client;
  bool _isInitialized = false;

  // --- INITIALIZATION ---

  void initVoiceAssistant({
    required Function(String) onMessageReceived,
    required Function(String) onStatusChanged,
    required Function(String) onError,
  }) {
    _client = ConversationClient(
      callbacks: ConversationCallbacks(
        onConnect: ({required conversationId}) {
          onStatusChanged("Connected");
        },
        // The SDK uses 'message' and 'source' for the onMessage callback
        onMessage: ({required message, required source}) {
          onMessageReceived("${source.name}: $message");
        },
        onError: (message, [context]) => onError(message),
      ),
    );

    _isInitialized = true;
  }

  // --- CORE VOICE FLOW ---

  Future<void> startSetupSession(String userId) async {
    if (!_isInitialized)
      throw Exception("VoiceAssistantService not initialized.");

    // Requesting permission is mandatory before starting
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted)
      throw Exception("Microphone permission denied.");

    try {
      // Fetch the signed token from your Flask backend
      final response = await http.get(
        Uri.parse('http://192.168.31.52/api/voice-session'),
      );

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['signed_url'];

        // Use 'conversationToken' for private agents to avoid exposing API keys
        await _client.startSession(conversationToken: token, userId: userId);
      } else {
        throw Exception("Failed to get signed session token.");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopSession() async {
    await _client.endSession(); // Standard method to end conversation
  }

  // --- CONTEXTUAL TOOLS ---

  /// Sends a background update to the agent that the user cannot see.
  /// Useful for telling the agent which setup step the user is on.
  void updateAgentContext(String info) {
    _client.sendContextualUpdate(info);
  }

  // --- MIC CONTROLS ---

  Future<void> toggleMute() async {
    await _client.toggleMute(); // Convenient toggle helper
  }

  void dispose() {
    _client.dispose(); // Always dispose to clean up WebRTC resources
  }
}

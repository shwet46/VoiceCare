import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:elevenlabs_agents/elevenlabs_agents.dart';

class VoiceService {
  late ConversationClient client;
  static const String apiUrl = 'http://192.168.31.52:5000/api/voice-session';

  void initialize({required ConversationCallbacks callbacks}) {
    client = ConversationClient(callbacks: callbacks);
  }

  Future<String?> fetchSignedUrl() async {
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['signed_url'];
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  void addListener(void Function() listener) => client.addListener(listener);
  void dispose() => client.dispose();
}

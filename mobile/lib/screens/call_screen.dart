import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/material.dart';

class AICallScreen extends StatefulWidget {
  const AICallScreen({super.key});
  @override
  State<AICallScreen> createState() => _AICallScreenState();
}

class _AICallScreenState extends State<AICallScreen> {
  late ConversationClient _client;
  List<Map<String, String>> transcript = [];

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  void _startConversation() {
    _client = ConversationClient(
      callbacks: ConversationCallbacks(
        onMessage: ({required message, required source}) {
          // setState(() {
          //   transcript.add({
          //     "role": source == MessageSource.agent ? "AI" : "User",
          //     "text": message,
          //   });
          // });
        },
      ),
    );
    _client.startSession(agentId: 'YOUR_ELEVENLABS_AGENT_ID');
  }

  Future<void> _endCall() async {
    await _client.endSession();
    // Save to Firestore
    // await FirebaseFirestore.instance.collection('logs').add({
    //   'date': DateTime.now(),
    //   'senior_id': 'user_01',
    //   'conversation': transcript,
    // });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 60)),
          const Text(
            "Speaking with VoiceCare...",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          const Spacer(),
          // End Call Button
          FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: _endCall,
            child: const Icon(Icons.call_end),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

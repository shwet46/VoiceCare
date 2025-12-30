import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallService {
  static void init(BuildContext context) {
    FlutterCallkitIncoming.onEvent.listen((event) {
      if (event!.event == Event.actionCallAccept) {
        // IMPORTANT: This is where you redirect to ElevenLabs UI
        Navigator.pushNamed(context, '/ai_call_screen', arguments: event.body);
      }
    });
  }
}

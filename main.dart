import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(TerminatorAI());
}

class TerminatorAI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terminator AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, String>> messages = [];
  TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  FlutterTts _flutterTts = FlutterTts();
  String apiKey = "PASTE_YOUR_OPENAI_API_KEY_HERE";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    setState(() {
      messages.add({'sender': 'You', 'text': message});
    });
    _controller.clear();

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': message}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final reply = json.decode(response.body)['choices'][0]['message']['content'];
      setState(() {
        messages.add({'sender': 'Terminator', 'text': reply});
      });
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.speak(reply);
    } else {
      setState(() {
        messages.add({'sender': 'Terminator', 'text': 'Error: Unable to get response'});
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          if (val.hasConfidenceRating && val.confidence > 0) {
            _controller.text = val.recognizedWords;
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Terminator AI")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]['sender']!),
                  subtitle: Text(messages[index]['text']!),
                );
              },
            ),
          ),
          Row(
            children: [
              IconButton(icon: Icon(_isListening ? Icons.mic_off : Icons.mic), onPressed: _listen),
              Expanded(
                child: TextField(controller: _controller, decoration: InputDecoration(hintText: 'Type here...')),
              ),
              IconButton(icon: Icon(Icons.send), onPressed: () => _sendMessage(_controller.text)),
            ],
          ),
        ],
      ),
    );
  }
}
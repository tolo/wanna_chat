import 'package:flutter/material.dart';
import 'package:wanna_chat_app/screens/chat_screen.dart';
import 'package:wanna_chat_app/widgets/extensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _baseUrl = TextEditingController(text: 'http://localhost:8080/chat');

  bool get canSignIn => _usernameController.text.isNotEmpty;

  void goToChat() {
    final conversationId = _usernameController.text;
    if (conversationId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ChatScreen(conversationId: conversationId, baseUrl: _baseUrl.text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Card(
          child: Container(
            constraints: BoxConstraints.loose(const Size(600, 800)),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Image(image: AssetImage('assets/banner.png')).padded(bottom: 16),
                Text('Sign in', style: context.headlineMedium),
                TextField(
                  decoration: const InputDecoration(labelText: 'Username', hintText: 'Enter a username/session ID'),
                  controller: _usernameController,
                  onChanged: (_) => setState(() {}),
                ).padded(all: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Server URL', hintText: 'Enter the base URL of the WannaChat backend server'),
                  controller: _baseUrl,
                ).padded(all: 16),
                FilledButton(
                  onPressed: canSignIn ? goToChat : null,
                  child: const Text('Sign in'),
                ).padded(all: 16),
              ],
            ),
          ),
        ),
      ).centered(),
    );
  }
}

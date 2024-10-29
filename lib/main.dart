import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';
import 'package:uuid/v1.dart';
import 'package:uuid/v4.dart';

void main() {
  //runApp(const MyApp());
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Chat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<types.Message> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  final _user = types.User(
    id: UniqueKey().toString(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(messages: messages, //abbiniamo il widget con i messaggi 
      onSendPressed: onSendPressed, 
      user: user),
    ));
  }

  void _loadMessage() async {
    final response = await rootBundle.loadString(
        "assets/messaggi.json"); //Prendiamo il contenuto del file json dentro la stringa
    final _messages = (jsonDecode(response)
            as List) // Lo deserializziamo in List di string
        .map((e) => types.Message.fromJson(e as Map<String,
            dynamic>)) //mappiamo  ogni elemento della lista in un oggetto Message
        .toList(); //Lo convertiamo in una lista di oggetti
    setState(() {
      messages = _messages;
    });
  }
}

// ignore_for_file: unused_local_variable, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:quickalert/quickalert.dart';
import 'package:restart_app/restart_app.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
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

    socket = IO.io('http://192.168.1.118:5000', <String, dynamic>{
      "transports": ["websocket"]
    });

    socket.on("connect", (_) {});

    socket.on("messageServer", (data) {
      setState(() {
        messageFromServer(data);
      });
    });

    @override
    void dispose() {
      _streamController.close();
      socket.dispose();
      super.dispose();
    }
  }

  // diego

  final _user = const types.User(
    id: 'bfb6f760-bfdf-418f-8350-26031128e34e',
    firstName: "Diego",
    lastName: "Vagnini",
  );

  //babbo
  // final _user = const types.User(
  //   id: 'd74db2c2-32b0-4f56-88a2-041eaab1fc1b',
  //   firstName: "Daniele",
  //   lastName: "Vagnini",
  // );

  late IO.Socket socket;
  final StreamController<String> _streamController = StreamController<String>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("GagioX Chat"),
          backgroundColor: const Color.fromARGB(255, 57, 21, 118),
          foregroundColor: Colors.white,
        ),
        body: Chat(
          messages: messages, //abbiniamo il widget con i messaggi
          onPreviewDataFetched: _handlePreviewDatafetched,
          onSendPressed: _handleSendPressed,
          showUserAvatars: true,
          showUserNames: true,
          user: _user,
          theme: const DarkChatTheme(
            backgroundColor: Colors.black,
            seenIcon: Text(
              "read",
              style: TextStyle(fontSize: 10),
            ),
          ),
        ));
  }

  void _loadMessage() async {
    // final String path = await GetPath();
    // final File file = File(path);
    List<types.Message> ExistingText = [];

    try {
      try {
        ExistingText = await JsonReading();
        //loadStatic();
        setState(() {
          messages += ExistingText;
          messages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
        });
      } catch (e) {
        //loadStatic();
      }
    } catch (e) {
      _showAlert("Error loading messages: $e");
    }
  }

  void messageFromServer(dynamic messaggio) {
    final bodyJson = json.decode(messaggio);

    final user = types.User(id: bodyJson['id']);

    final types.TextMessage messaggioNuovo = types.TextMessage(
        author: types.User(
            id: bodyJson['author']['id'],
            firstName: bodyJson['author']['firstName'],
            lastName: bodyJson['author']['lastName']),
        text: bodyJson['text'],
        id: bodyJson['id'],
        createdAt: DateTime.now().millisecondsSinceEpoch);

    addMessage(messaggioNuovo);
  }

  void DeleteJson() async {
    final String path = await GetPath();
    final File file = File(path);

    file.delete();
  }

  void _handlePreviewDatafetched(types.TextMessage p1, types.PreviewData p2) {
    final int index =
        messages.indexWhere((types.Message element) => element.id == p1.id);
    final types.Message updatedMessage =
        (messages[index] as types.TextMessage).copyWith(previewData: p2);
    /*Questa funzione recupera i messaggi contenuti nei messaggi.json e li mette sul body della mia
    applicazione. In particola trova l’indice del messaggio nella lista _messaggi, ne crea una copia ed
    aggiorna la lista*/
  }

  void AggiungiAlJson(types.TextMessage message) async {
    final String path = await GetPath();
    final File file = File(path);

    try {
      List<types.TextMessage> existingMessages = [];
      if (await file.exists()) {
        String jsonContent = await file.readAsString();
        if (jsonContent.isNotEmpty) {
          existingMessages = (jsonDecode(jsonContent) as List)
              .map((e) => types.TextMessage.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      existingMessages.add(message); // Aggiungi il nuovo messaggio
      String newJsonContent =
          jsonEncode(existingMessages); // Serializza l'intero array
      await file.writeAsString(newJsonContent); // Scrivi tutto nel file
    } catch (e) {
      _showAlert("Error writing message: $e");
    }
  }

  void _handleSendPressed(types.PartialText p1) async {
    String room = "";

    if (p1.text.isNotEmpty) {
      final types.TextMessage textMessage = types.TextMessage(
        author: _user,
        id: const Uuid().v4(),
        text: p1.text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      //_showAlert(textMessage.toString());

      switch (textMessage.text) {
        case "/delete":
          DeleteJson();
          sleep(const Duration(milliseconds: 500));
          Restart.restartApp();
          break;
        default:
          addMessage(textMessage);
          socket.emit('sendMessage', textMessage);
          break;
      }

      if (textMessage.text.contains('/join')) {
        socket.emit('join', textMessage.text.substring(6));
      }

    } else {
      _showAlert("Message cannot be empty");
    }
  }

  Future<String> GetPath() async {
    final dir = await getApplicationCacheDirectory();
    return '${dir.path}/MessaggiDinamici11.json';
  }

  void addMessage(types.TextMessage message) async {
    AggiungiAlJson(message);
    setState(() {
      messages.add(message);
      messages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    });
  }

  Future<List<types.Message>> JsonReading() async {
    final String path = await GetPath();
    final File file = File(path);
    List<types.Message> messagesJson = [];
    if (await file.exists()) {
      String jsonContent = await file.readAsString();
      if (jsonContent.isNotEmpty) {
        messagesJson = (jsonDecode(jsonContent) as List)
            .cast()
            .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
            .toList();
        return messagesJson;
      }
    }
    messagesJson = [];
    return messagesJson;
  }

  void _showAlert(String string) {
    QuickAlert.show(context: context, type: QuickAlertType.info, text: string);
  }
}

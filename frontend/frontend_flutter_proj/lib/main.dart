// ignore_for_file: unused_local_variable, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:quickalert/quickalert.dart';

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

    socket = IO.io('http://192.168.101.9:4500', <String, dynamic>{
      "transports": ["websocket"]
    });

    socket.on("connect", (_) {
      setState(() {
        _showAlert("Client connesso al server");
      });
    });

    socket.on("message", (data) {
      _streamController.add(data);
    });

    @override
    void Dispose() {
      _streamController.close();
      super.dispose();
    }
  }

  final _user = types.User(
    id: 'bfb6f760-bfdf-418f-8350-26031128e34e',
    firstName: "Diego",
    lastName: "Vagnini",
  );

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

  void loadStatic() async {
    final response = await rootBundle.loadString(
        "assets/messaggi.json"); //Prendiamo il contenuto del file json dentro la stringa
    //final List<Message> dynJson = await readJsonDy();
    final _messages = (jsonDecode(response)
            as List) // Lo deserializziamo in List di string
        .map((e) => types.Message.fromJson(e as Map<
            String, //Qua devo caricare il json statico e dinamico
            dynamic>)) //mappiamo  ogni elemento della lista in un oggetto Message
        .toList(); //Lo convertiamo in una lista di oggetti

    setState(() {
      messages = _messages;
      //_showAlert(messages.toString());
      messages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    });
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

  void _handlePreviewDatafetched(types.TextMessage p1, types.PreviewData p2) {
    final int index =
        messages.indexWhere((types.Message element) => element.id == p1.id);
    final types.Message updatedMessage =
        (messages[index] as types.TextMessage).copyWith(previewData: p2);
    /*Questa funzione recupera i messaggi contenuti nei messaggi.json e li mette sul body della mia
    applicazione. In particola trova l’indice del messaggio nella lista _messaggi, ne crea una copia ed
    aggiorna la lista*/
  }

  void _handleSendPressed(types.PartialText p1) async {
    if (p1.text.isNotEmpty) {
      // Check if the message text is not empty
      final types.TextMessage textMessage = types.TextMessage(
        author: _user,
        id: const Uuid().v4(),
        text: p1.text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      // addMessage(textMessage);
      // final response = await http.post(
      //     Uri.parse(
      //         "http://192.168.223.9:3000/submit"), // indirizzo del server da cambiare
      //     headers: {'Content-Type': 'application/json'},
      //     body: jsonEncode(textMessage));
      // _showAlert(jsonDecode(response.body)['text']);

      socket.emit('sendMessage', textMessage);
      addMessage(textMessage);
    } else {
      _showAlert("Message cannot be empty"); // Alert for empty messages
    }
  }

  Future<String> GetPath() async {
    final dir = await getApplicationCacheDirectory();
    return '${dir.path}/MessaggiDinamici8.json';
  }

  void addMessage(types.TextMessage message) async {
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

    setState(() {
      messages.add(message);
      messages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    });

    initState();
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

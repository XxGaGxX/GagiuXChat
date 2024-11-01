// ignore_for_file: unused_local_variable, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
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
  late List<dynamic> mesJsonDy;

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  final _user = types.User(
    id: const Uuid().v4(),
    firstName: "Diego",
    lastName: "Vagnini",
  );

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
      //messages += dynJson.cast<types.Message>();
      messages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    });
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

  void _handleSendPressed(types.PartialText p1) {
    final types.TextMessage textMessage = types.TextMessage(
        author: _user,
        id: const Uuid().v4(),
        text: p1.text,
        createdAt: DateTime.now().millisecondsSinceEpoch);
    addMessage(textMessage);
  }


  void addMessage(types.TextMessage message) async {
    setState(() {
      messages.insert(0,
          message); // Qui devo caricare il messaggio anche nell'JSON dinamico
    });
  }


  void _showAlert(String string) {
    QuickAlert.show(context: context, type: QuickAlertType.info, text: string);
  }
}



/* 
    Prossimo step :
    Bisogna aggiornare il codice per gestire la scrittura di nuovi messaggi, 
    se l'utente scriverà un nuovo messaggio, dovrà essere caricato nel JSON dinamico,
    per poi manualmente chiamare _loadMessages(), dove al suo interno verrà aggiunta una parte
    che caricherà i messaggi contenuti nel JSON dinamico, e li aggiungerà alla lista dei messaggi.
*/

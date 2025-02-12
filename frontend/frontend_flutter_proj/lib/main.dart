// ignore_for_file: unused_local_variable, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:frontend_flutter_proj/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:quickalert/quickalert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:restart_app/restart_app.dart';
import 'package:uuid/v4.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
  List<types.User> users = [];
  String IP = '192.168.1.122';

  @override
  void initState() {
    super.initState();
    _loadMessage();

    socket = IO.io('http://${IP}:5000', <String, dynamic>{
      "transports": ["websocket"]
    });

    socket.on("connect", (_) {});

    socket.on("messageServer", (data) {
      messageFromServer(data);
    });

    @override
    void dispose() {
      _streamController.close();
      socket.dispose();
      super.dispose();
    }
  }

  var _user = const types.User(id: '', firstName: "", imageUrl: "");

  String room = '';
  late IO.Socket socket;
  final StreamController<String> _streamController = StreamController<String>();
  String? _nomeUtente, _id, _errore, _image;
  String? _nomeUtenteDest, _idDest, _imageDest;

  @override
  Widget build(BuildContext context) {
    if (_nomeUtente == null || _nomeUtente!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SignInButton(
                Buttons.google,
                onPressed: () {
                  _login();
                },
              ),
              Text(_errore ?? ''),
            ],
          ),
        ),
      );
    } else {
      if (room.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("GagioX Chat"),
            backgroundColor: const Color.fromARGB(255, 57, 21, 118),
            foregroundColor: Colors.white,
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  child: CircleAvatar(
                    backgroundColor: Colors.black,
                    backgroundImage: _user.imageUrl != null
                        ? NetworkImage(_user.imageUrl!)
                        : null,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text("Hi " + _user.firstName!)],
                ),
                ListTile(
                  title: const Text("Logout"),
                  onTap: () {
                    Logout();
                  },
                ),
                ListTile(
                  title: const Text("Change server IP"),
                  subtitle: TextField(
                    decoration: InputDecoration(
                        suffixIcon: Icon(Icons.arrow_forward_ios_outlined)),
                    onSubmitted: (value) {
                      setState(() {
                        IP = value;
                        QuickAlert.show(
                            context: context,
                            type: QuickAlertType.info,
                            text: IP);
                      });
                    },
                  ),
                  onTap: () {},
                )
              ],
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(5),
            itemCount: users.length,
            itemBuilder: (BuildContext context, int index) {
              return Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        room = users[index].id;
                        _nomeUtenteDest = users[index].firstName;
                        _imageDest = users[index].imageUrl;
                      });
                    },
                    child: SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30.0,
                            backgroundColor: Colors.black,
                            backgroundImage: users[index].imageUrl != null
                                ? NetworkImage(users[index].imageUrl!)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(users[index].firstName.toString())
                        ],
                      ),
                    ),
                  ));
            },
          ),
        );
      } else {
        return Scaffold(
            appBar: AppBar(
              title: const Text("GagioX Chat"),
              backgroundColor: const Color.fromARGB(255, 57, 21, 118),
              foregroundColor: Colors.white,
            ),
            drawer: Drawer(
              child: ListView(
                children: [
                  DrawerHeader(
                    child: CircleAvatar(
                      backgroundColor: Colors.black,
                      backgroundImage: _user.imageUrl != null
                          ? NetworkImage(_user.imageUrl!)
                          : null,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text("Hi " + _user.firstName!)],
                  ),
                  ListTile(
                    title: const Text("Logout"),
                    onTap: () {
                      Logout();
                    },
                  ),
                  ListTile(
                    title: const Text("Change server IP"),
                    subtitle: TextField(
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.arrow_forward_ios_outlined)
                      ),
                      onSubmitted: (value) {
                        setState(() {
                          IP = value;
                          QuickAlert.show(
                              context: context,
                              type: QuickAlertType.info,
                              text: IP);
                        });
                      },
                    ),
                    onTap: () {},
                  )
                ],
              ),
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
    }
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

  void ChangeServerIP() {
    setState(() {});
  }

  Future<void> _login() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return; // l'utente ha annullato il login
      } else {
        final GoogleSignInAuthentication googleAuth = await googleUser
            .authentication; // ottengo i dati di autenticazione dall'account google
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ); //creo delle credenziali per firebase con i dati di autenticazione dell'account google
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(
                credential); // faccio il login su Firebase con le credenziali di google
        User? user = userCredential.user;
        if (user != null) {
          setState(() {
            _nomeUtente = user.displayName;
            _id = user.uid;
            _image = user.photoURL;
          });
          CredenzialiUtente();
          users = FindUsers();
          socket.emit('join', _user.id);
        }
      }
    } catch (e) {
      setState(() {
        _errore = e.toString();
      });
    }
  }

  Future<void> Logout() async {
    try {
      await GoogleSignIn().signOut();
      setState(() {
        _user = types.User(id: "", firstName: "", imageUrl: "");
        _nomeUtente = null;
        room = "";
      });
    } catch (e) {
      setState(() {});
    }
  }

  List<types.User> FindUsers() {
    List<types.User> users = [];
    messages.forEach((element) async {
      types.User user = element.author;
      if (!users.contains(user) && user.id != _user.id) {
        users.add(user);
      }
    });
    return users;
  }

  void CredenzialiUtente() async {
    setState(() {
      _user = types.User(id: _id!, firstName: _nomeUtente, imageUrl: _image);
    });
  }

  void messageFromServer(dynamic messaggio) {
    final bodyJson = json.decode(messaggio);

    final user = types.User(id: bodyJson['id']);

    final types.TextMessage messaggioNuovo = types.TextMessage(
        author: types.User(
            id: bodyJson['author']['id'],
            firstName: bodyJson['author']['firstName'],
            lastName: bodyJson['author']['lastName'],
            imageUrl: bodyJson['author']['imageUrl']),
        text: bodyJson['text'],
        id: bodyJson['id'],
        createdAt: DateTime.now().millisecondsSinceEpoch,
        roomId: bodyJson['roomId']);

    addMessage(messaggioNuovo);
  }

  void DeleteJson() async {
    final String path = await GetPathText();
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
    final String path = await GetPathText();
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
    if (p1.text.isNotEmpty) {
      if (p1.text.contains('/join')) {
        socket.emit('join', p1.text.substring(6));
        setState(() {
          room = p1.text.substring(6);
        });
      } else {
        switch (p1.text) {
          case "/clear":
            DeleteJson();
            sleep(const Duration(milliseconds: 500));
            Restart.restartApp();

            break;
          default:
            types.TextMessage text = _createTextMessage(p1);
            addMessage(text);
            socket.emit('sendMessage', text);
            break;
        }
      }
    } else {
      _showAlert("Message cannot be empty");
    }
  }

  types.TextMessage _createTextMessage(types.PartialText p1) {
    final types.TextMessage textMessage = types.TextMessage(
        author: _user,
        id: const Uuid().v4(),
        text: p1.text,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        roomId: room);
    return textMessage;
  }

  Future<String> GetPathText() async {
    final dir = await getApplicationCacheDirectory();
    return '${dir.path}/MessaggiDinamici11.json';
  }

  Future<String> GetPathUser() async {
    final dir = await getApplicationCacheDirectory();
    return '${dir.path}/user.json';
  }

  void addMessage(types.TextMessage message) async {
    AggiungiAlJson(message);
    setState(() {
      messages.add(message);
      messages.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    });
  }

  Future<List<types.Message>> JsonReading() async {
    final String path = await GetPathText();
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

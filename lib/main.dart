import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;
  StompClient? stompClient;
  String receivedMessage = "No messages yet";

  void _incrementCounter_thenConnectToWebSocket() {
    setState(() {
      _counter++;
    });
  }

  void _connectToWebSocket() {
    stompClient = StompClient(
      config: StompConfig.SockJS(
        url: webSocketUrl,
        onConnect: onConnectCallback,
        beforeConnect: beforeConnectToWebSocket,
        connectionTimeout: Duration(seconds: 10),
        reconnectDelay: Duration(seconds: 0),
        onStompError: onStompErrorCallback,
        onDisconnect: onDisconnectCallback,
        onWebSocketError: onWebSocketErrorCallback,
      ),
    );
    stompClient!.activate();
  }

  void disconnect() {
    stompClient?.deactivate();
    setState(() {
      receivedMessage = "Disconnected";
    });
  }

  Future<void> beforeConnectToWebSocket() async {
    print('_____Connecting to webSocket at url $webSocketUrl');
    setState(() {
      receivedMessage = "Connecting to $webSocketUrl ...";
    });
  }

  void onStompErrorCallback(StompFrame frame) {
    print("_______ StompErrorCallback");
    setState(() {
      receivedMessage = frame.body ?? "StompErrorCallback";
    });
  }

  void onDisconnectCallback(StompFrame frame) {
    print("_______ DisconnectCallback");
    setState(() {
      receivedMessage = frame.body ?? "DisconnectCallback";
    });
  }

  void onWebSocketErrorCallback(dynamic error) {
    print("_______ WebSocketErrorCallback caused by $error");
    setState(() {
      receivedMessage =
          error.toString() ?? "Error when connecting to websocket";
    });
  }

  void onConnectCallback(StompFrame frame) {
    print('_________Connected!');
    stompClient!.subscribe(
      destination: '$SOCKET_RECEIVE_PREFIX$SOCKET_RECEIVE_MESSAGE_CHANNEL',
      callback: (frame) {
        setState(() {
          receivedMessage = frame.body ?? "Empty message";
        });
      },
    );

    // Send a test message once connected
    stompClient!.send(
      destination: '$SOCKET_SUBS_PREFIX$SOCKET_SUBS_CHAT_CHANNEL',
      body: '{"user":"flutter client","message":"test message"}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Message received from websocket'),
            // Text(
            //   '$_counter',
            //   style: Theme.of(context).textTheme.headlineMedium,
            // ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    receivedMessage,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _connectToWebSocket,
                    child: Text("Connect to websocket"),
                  ),
                  ElevatedButton(
                    onPressed: disconnect,
                    child: Text("Disconnect from websocket"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter_thenConnectToWebSocket,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

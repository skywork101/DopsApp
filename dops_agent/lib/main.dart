import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Location _location = Location();
  WebSocketChannel? _channel;
  Socket? _channel_2;
  bool _isConnected = false;
  bool _isSendingGPS = false;
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _locationTimer;
  LocationData? _currentLocation;
  final String? _deviceId = "ssss";

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  void _initLocationService() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    LocationData locationData = await _location.getLocation();
    _locationSubscription =
        _location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentLocation = currentLocation;
      });

      if (_isSendingGPS) {
        _sendLocationData2(currentLocation);
      }
    });
  }

  void _connectToWebSocket() {
    final channel = IOWebSocketChannel.connect('ws://192.168.1.71:13113');

    setState(() {
      _channel = channel;
      _isConnected = true;
    });
  }

  void _connectToSocket() async {
    try {
      print('connecting to socket');
      final socket = await Socket.connect('192.168.1.71', 13113);
      setState(() {
        _channel_2 = socket;
        _isConnected = true;
      });

      // Handle incoming data from the server (if needed).
      socket.listen((Uint8List data) {
        // Handle incoming data here.
        // For example, you can convert it to a string: String.fromCharCodes(data);
        print(String.fromCharCodes(data));
      });
    } catch (e) {
      print('Error connecting to socket: $e');
    }
  }

  void _sendLocationData2(LocationData locationData) {
    if (_channel != null && _deviceId != null) {
      final data = {
        'type': 'location_data',
        'id': _deviceId,
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
      };

      _channel!.sink.add(json.encode(data));
    }
  }

  void _sendLocationData(LocationData locationData) {
    if (_channel_2 != null && _deviceId != null) {
      final data = {
        'type': 'location_data',
        'id': _deviceId,
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
      };
      print('sent msg to socket: $data');
      final jsonData = json.encode(data);
      final dataToSend = Uint8List.fromList(utf8.encode(jsonData));
      final dataToSend_2 = utf8.encode('\n'); // Add a newline delimiter
      _channel_2!.write(dataToSend);
      _channel_2!.write(dataToSend_2);
    }
  }

  void _sendmsg() async {
    if (_channel_2 != null && _deviceId != null) {
      const data = {
        'type': 'location_data',
        'id': '_deviceId',
        'latitude': 'locationData.latitude',
        'longitude': 'locationData.longitude',
      };
      print('sent msg to socket: $data');
      final jsonData = json.encode(data);
      final dataToSend = Uint8List.fromList(utf8.encode(jsonData));
      // final dataToSend = utf8.encode(jsonData + '\n'); // Add a newline delimiter
      _channel_2!.write(jsonData);
      // await _channel_2!.flush();
      // await Future.delayed(const Duration(seconds: 1));
      _channel_2!.write("\n");
    }
  }

  void _toggleSendingGPS() {
    setState(() {
      _isSendingGPS = !_isSendingGPS;

      if (_isSendingGPS) {
        // Start sending GPS data at a 1-second interval
        _locationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          if (_currentLocation != null) {
            _sendLocationData(_currentLocation!);
          }
        });
      } else {
        // Stop the location timer
        _locationTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();

    _locationSubscription?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dops Agent'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isConnected ? null : _connectToSocket,
              child: Text(_isConnected ? 'Connected' : 'Request Connection'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConnected ? _toggleSendingGPS : null,
              child: Text(
                  _isSendingGPS ? 'Stop Sending GPS' : 'Start Sending GPS'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendmsg,
              child: Text('send test'),
            )
          ],
        ),
      ),
    );
  }
}

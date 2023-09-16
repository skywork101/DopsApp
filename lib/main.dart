import 'dart:async';
import 'dart:convert';
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
  bool _isConnected = false;
  bool _isSendingGPS = false;
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _locationTimer;
  LocationData? _currentLocation;
  String? _deviceId;

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
        _sendLocationData(currentLocation);
      }
    });
  }

  void _connectToWebSocket() {
    final channel = IOWebSocketChannel.connect('ws://192.168.1.71:13113');
/*
    channel.stream.listen((message) {
      final data = json.decode(message);
      if (data['type'] == 'connection_granted') {
        // Connection granted, server sent an ID
        setState(() {
          _deviceId = data['id'];
          _isConnected = true;
        });
      }
    });



    print("here");
    channel.stream.listen((dynamic message) {
      print(message);
      if (message is Uint8List) {
        // Assuming the message received is a byte array (Uint8List)
        String jsonString =
            utf8.decode(message); // Convert bytes to a JSON string
        Map<String, dynamic> data =
            json.decode(jsonString); // Parse JSON string to a Map

        if (data['type'] == 'connection_granted') {
          // Connection granted, server sent an ID
          setState(() {
            _deviceId = data['id'];
            _isConnected = true;
          });
        }
      }
    });
*/
    setState(() {
      _channel = channel;
      _isConnected = true;
    });
  }

  void _sendLocationData(LocationData locationData) {
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
              onPressed: _isConnected ? null : _connectToWebSocket,
              child: Text(_isConnected ? 'Connected' : 'Request Connection'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConnected ? _toggleSendingGPS : null,
              child: Text(
                  _isSendingGPS ? 'Stop Sending GPS' : 'Start Sending GPS'),
            ),
          ],
        ),
      ),
    );
  }
}

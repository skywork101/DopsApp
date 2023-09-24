import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Socket? _socket;
  bool _isConnected = false;
  bool _isSendingLocation = false;

  void _toggleConnection() async {
    if (_isConnected) {
      _socket?.close();
      setState(() {
        _isConnected = false;
      });
    } else {
      try {
        final socket = await Socket.connect('192.168.0.103', 13313);

        print('Connected to server');

        socket.listen(
          (data) {
            final message = utf8.decode(data);
            print('Received message: $message');

            // Process the received message or update UI accordingly
          },
          onError: (error) {
            print('Error: $error');
            socket.close();
          },
          onDone: () {
            print('Connection closed');
            socket.close();
          },
        );
        setState(() {
          _socket = socket;
          _isConnected = true;
        });
      } catch (e) {
        print('Connection error: $e');
      }
    }
  }

  void _toggleSendingLocation() {
    setState(() {
      _isSendingLocation = !_isSendingLocation;
    });

    if (_isSendingLocation) {
      _sendLocation();
    }
  }

  void _sendLocation() async {
    while (_isSendingLocation) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final locationData = 'Latitude: ${position.latitude}, '
            'Longitude: ${position.longitude}';
        _socket?.write(locationData);
        _socket?.write("\n");
        print("location sent $locationData");
      } catch (e) {
        print('Location sending error: $e');
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }

  void _sendmsg() async {
    const locationData = 'hello bitch';
    _socket?.write(locationData);
    _socket?.write("\n");
    print("location sent $locationData");
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('TCP Socket Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _toggleConnection,
                child: Text(_isConnected ? 'Disconnect' : 'Connect'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_isConnected) {
                    _toggleSendingLocation();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Connection Error'),
                          content: Text('Please connect to the server.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child:
                    Text(_isSendingLocation ? 'Stop Sending' : 'Start Sending'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendmsg,
                child: Text(_isConnected ? 'send message' : 'connect first'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

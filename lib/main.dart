import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Time'),
        ),
        body: const Center(
          child: ResponseTime(),
        ),
      ),
    );
  }
}

class ResponseTime extends StatefulWidget {
  const ResponseTime({super.key});

  @override
  ResponseTimeState createState() => ResponseTimeState();
}

class ResponseTimeState extends State<ResponseTime> {
  String _responseTime = '';
  String _downloadTime = '';
  Image? _image;  // Make _image nullable
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'ENTER IMAGE URL',
          ),
        ),
        ElevatedButton(
          onPressed: _getResponseTime,
          child: const Text('Get Response and Download Time'),
        ),
        Text(
          _responseTime,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _downloadTime,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        _image != null ? _image! : Container(),
      ],
    );
  }

  Future<void> _getResponseTime() async {
    // Hide the keyboard
    FocusScope.of(context).unfocus();

    String imageUrl = _controller.text;

    // Parse the URL to get the domain
    var uri = Uri.parse(imageUrl);
    String serverAddress = uri.host;

    try {
      // Establish connection
      Socket socket = await Socket.connect(serverAddress, 80);

      // Send request
      socket.writeln("GET / HTTP/1.1");
      socket.writeln();

      // Measure response time
      Stopwatch stopwatch = Stopwatch()..start();
      await socket.flush();
      // await until get the first response from server
      // In other words, server responded
      await socket.first;
      stopwatch.stop();

      // Update response time
      setState(() {
        _responseTime = 'Server Response Time: ${stopwatch.elapsedMilliseconds} ms';
      });

      // Close the socket
      socket.close();

      // Measure image download time
      stopwatch.reset();
      stopwatch.start();
      // await until the image is being parsed or downloaded
      var response = await http.get(Uri.parse(imageUrl));
      stopwatch.stop();

      // Check if the response was successful
      if (response.statusCode == 200) {
        // Update download time
        setState(() {
          _downloadTime = 'Image Download Time: ${stopwatch.elapsedMilliseconds} ms';
          _image = Image.network(imageUrl);
        });
      } else {
        throw Exception('Wrong Image URL');
      }
    } catch (e) {
      // Handle the error
      setState(() {
        _responseTime = '$e';
        _downloadTime = '';
        _image = null;
      });
    }
  }
}

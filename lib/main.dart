import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serial Communication',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SerialCommunicationScreen(),
    );
  }
}

class SerialCommunicationScreen extends StatefulWidget {
  const SerialCommunicationScreen({super.key});

  @override
  _SerialCommunicationScreenState createState() =>
      _SerialCommunicationScreenState();
}

class _SerialCommunicationScreenState extends State<SerialCommunicationScreen> {
  List<String> availablePorts = [];
  SerialPort? selectedPort;
  SerialPortReader? reader;
  String receivedData = "";
  String sendData = ""; // Data to send to Arduino
  bool isPortOpen = false;

  @override
  void initState() {
    super.initState();
    _getAvailablePorts();
  }

  // Fetch available serial ports
  void _getAvailablePorts() {
    setState(() {
      availablePorts = SerialPort.availablePorts;
    });
  }

  void _openPort(String portName) {
    final port = SerialPort(portName);
    port.config.baudRate = 9600; // Match with Arduino
    port.config.stopBits = 1;
    port.config.parity = 0;

    if (port.openReadWrite()) {
      setState(() {
        selectedPort = port;
        isPortOpen = true;
      });
      _startListening(port);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Port $portName opened successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open port: $portName')),
      );
      setState(() {
        selectedPort = null;
        isPortOpen = false;
      });
    }
  }

  // Start listening to data from the serial port
  void _startListening(SerialPort port) {
    reader = SerialPortReader(port);
    reader!.stream.listen((data) {
      final receivedString = String.fromCharCodes(data);
      setState(() {
        receivedData += receivedString; // Append received data
      });
    });
  }

  // Send data to Arduino
  void _sendDataToArduino() {
    if (selectedPort != null && selectedPort!.isOpen) {
      selectedPort!.write(const Utf8Encoder().convert('$sendData\n')); // Send data with newline
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data sent: $sendData')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Port not open')),
      );
    }
  }

  // Close the selected port
  void _closePort() {
    reader?.close();
    selectedPort?.close();
    setState(() {
      isPortOpen = false;
      selectedPort = null;
    });
  }

  @override
  void dispose() {
    _closePort();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serial Communication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available Ports:'),
            DropdownButton<String>(
              hint: const Text("Select a Port"),
              value: selectedPort?.name,
              items: availablePorts
                  .map((port) => DropdownMenuItem(
                        value: port,
                        child: Text(port),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) _openPort(value);
              },
            ),
            const SizedBox(height: 20),
            if (isPortOpen) ...[
              const Text('Connected to Port:'),
              Text(
                selectedPort?.name ?? 'No port selected',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),
              const Text('Received Data:'),
              Container(
                padding: const EdgeInsets.all(8.0),
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(receivedData),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Send Data to Arduino:'),
              TextField(
                onChanged: (value) {
                  setState(() {
                    sendData = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Data to Send',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendDataToArduino,
                child: const Text('Send Data'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _closePort,
                child: const Text('Close Port'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

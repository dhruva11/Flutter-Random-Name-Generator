import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(RandomNameGeneratorApp());
}

class RandomNameGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Name Generator',
      home: RandomNameGeneratorScreen(),
    );
  }
}

class RandomNameGeneratorScreen extends StatefulWidget {
  @override
  _RandomNameGeneratorScreenState createState() =>
      _RandomNameGeneratorScreenState();
}

class _RandomNameGeneratorScreenState extends State<RandomNameGeneratorScreen> {
  final List<String> _generatedNames = [];
  int _numberOfNames = 1; // Default number of names to generate
  bool _isLoading = false;
  bool _stopGeneration = false;

  // Function to generate a random name from the "Random User Generator" API
  Future<String> _fetchRandomName(String category) async {
    if (_stopGeneration) {
      return 'Generation Stopped';
    }

    String firstName;
    String gender;

    final response = await http.get(Uri.parse(
        'https://randomuser.me/api/?results=$_numberOfNames&gender=$category'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      firstName = data['results'][0]['name']['first'];
      gender = data['results'][0]['gender'];

      String languageCode = data['results'][0]['nat'];
      if ((languageCode == 'US' || languageCode == 'GB') &&
          ((category == 'male' && gender == 'male') ||
              (category == 'female' && gender == 'female'))) {
        return firstName;
      } else {
        // Retry fetching a valid name if the conditions are not met
        return await _fetchRandomName(category);
      }
    } else {
      setState(() {
        _generatedNames.add('Failed to fetch name');
        _isLoading = false;
      });
      return 'Failed to fetch name'; // Handle API call failure
    }
  }

  // Function to handle name generation based on category
  void _generateRandomNames(String category) {
    _generatedNames.clear();
    setState(() {
      _isLoading = true;
      _stopGeneration = false;
    });

    List<Future<String>> nameFutures = List.generate(
      _numberOfNames,
          (_) => _fetchRandomName(category),
    );

    Future.wait(nameFutures).then((names) {
      setState(() {
        _generatedNames.addAll(names);
        _isLoading = false;
      });
    });
  }

  // Function to reset the generated names list
  void _resetGeneratedNames() {
    if (_isLoading) {
      _stopGeneration = true;
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _generatedNames.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Random Name Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Number of Names to Generate:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _numberOfNames = int.tryParse(value) ?? 1;
                });
              },
              decoration: InputDecoration(
                labelText: 'Enter a number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: [
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _generateRandomNames('male'),
                  child: Text('Generate Male Name'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _generateRandomNames('female'),
                  child: Text('Generate Female Name'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _generatedNames.map((name) => ListTile(
                    title: Text(name),
                  )).toList(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _resetGeneratedNames,
              child: Text(_isLoading ? 'Stop Generation' : 'Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

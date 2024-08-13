import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 38, 65, 79),
      ),
      home: MyHomePage(title: 'Pomodoro'),
    );
  }
}

enum Mode {
  focus,
  chill,
}

const int initialTimeFocus = 4;
const int initialTimeChill = 2;

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  Mode _mode = Mode.focus;

  void toggleMode() {
    setState(() {
      _mode = _mode == Mode.focus ? Mode.chill : Mode.focus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mode == Mode.focus ? Colors.red : Colors.blue,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Pomodoro(initialTimeFocus: 2, initialTimeChill: 1, toggleMode: toggleMode),
      ),
    );
  }
}

class Pomodoro extends StatefulWidget {
  final int initialTimeFocus;
  final int initialTimeChill;
  final Function toggleMode;

  Pomodoro({
    required this.initialTimeFocus, 
    required this.initialTimeChill,
    required this.toggleMode,
  });

  @override
  _PomodoroState createState() => _PomodoroState();
}

class _PomodoroState extends State<Pomodoro> {
  late int _remainingTime;
  late int _initialTime;
  late Mode _mode;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _mode = Mode.focus;
    _initialTime = widget.initialTimeFocus;
    _remainingTime = _initialTime;
  }

  void _changeMode() {
    switch (_mode) {
      case Mode.focus:
        _mode = Mode.chill;
        _initialTime = widget.initialTimeChill;
        _remainingTime = _initialTime;
        break;
      case Mode.chill:
        _mode = Mode.focus;
        _initialTime = widget.initialTimeFocus;
        _remainingTime = _initialTime;
        break;
    }
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer!.cancel();
          widget.toggleMode();
          _changeMode();
        }
      });
    });
  }

  void _resetTimer() {
    setState(() {
      _remainingTime = _initialTime;
    });
    _startTimer();
  }

  void _pauseTimer() {
    _timer!.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    final String formattedMinutes = minutes.toString().padLeft(2, '0');
    final String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');
    return '$formattedMinutes:$formattedSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          formatTime(_remainingTime),
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _startTimer,
          child: Text('Start Timer'),
        ),
        ElevatedButton(
          onPressed: _resetTimer,
          child: Text("Reset Timer"),
        ),
        ElevatedButton(
          onPressed: _pauseTimer,
          child: Text("Pause Timer"),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => PomodoroMode(),
      child: MyApp()
    ),
  );
}

enum Mode {
    focus,
    chill,
}

class PomodoroMode extends ChangeNotifier {
  Mode mode = Mode.focus;

  Mode toggleMode() {
    mode = mode == Mode.focus ? Mode.chill : Mode.focus;
    notifyListeners();
    return mode;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroMode>(
      builder: (context, pomodoroMode, child) => MaterialApp(
        title: 'Pomodoro',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            brightness: MediaQuery.platformBrightnessOf(context),
            seedColor: pomodoroMode.mode == Mode.focus ? Colors.lightBlue : Colors.yellow,
          ),
        ),
        home: PomodoroPage(title: 'Pomodoro'),
      ),
    );
  }
}

const int initialTimeFocus = 4;
const int initialTimeChill = 2;

class PomodoroPage extends StatelessWidget {
  final String title;

  PomodoroPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Pomodoro(initialTimeFocus: 2, initialTimeChill: 1),
      ),
    );
  }
}

class Pomodoro extends StatefulWidget {
  final int initialTimeFocus;
  final int initialTimeChill;

  Pomodoro({
    required this.initialTimeFocus, 
    required this.initialTimeChill,
  });

  @override
  _PomodoroState createState() => _PomodoroState();
}

class _PomodoroState extends State<Pomodoro> {
  late int _remainingTime;
  late int _initialTime;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _initialTime = widget.initialTimeFocus;
    _remainingTime = _initialTime;
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
          Mode currentMode = context.read<PomodoroMode>().toggleMode();
          _initialTime = currentMode == Mode.focus ? widget.initialTimeFocus : widget.initialTimeChill;
          _remainingTime = _initialTime;
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64.0,
              height: 64.0,
              child: IconButton(
                icon: Icon(Icons.play_arrow, size: 48.0),
                onPressed: _startTimer,
              ),
            ),
            SizedBox(
              width: 64.0,
              height: 64.0,
              child: IconButton(
                icon: Icon(Icons.restart_alt, size: 48.0),
                onPressed: _resetTimer,
              ),
            ),
            SizedBox(
              width: 64.0,
              height: 64.0,
              child: IconButton(
                icon: Icon(Icons.pause, size: 48.0),
                onPressed: _pauseTimer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
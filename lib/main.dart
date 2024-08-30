import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
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
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: PomodoroPage(title: 'Pomodoro'),
      ),
    );
  }
}


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

  late bool _isTimerRunning = false;

  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initialTime = widget.initialTimeFocus;
    _remainingTime = _initialTime;
    _updateTextFields();
  }

  Future<void> _playSound() async {
    await player.play(AssetSource('timer-sound.mp3'));
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          _updateTextFields();
        } else {
          _timer!.cancel();
          _isTimerRunning = false;
          _playSound();
          Mode currentMode = context.read<PomodoroMode>().toggleMode();
          _initialTime = currentMode == Mode.focus ? widget.initialTimeFocus : widget.initialTimeChill;
          _remainingTime = _initialTime;
          _updateTextFields();
        }
      });
    });
  }

  void _resetTimer() {
    _remainingTime = _initialTime;
    _updateTextFields();
    _startTimer();
  }

  void _pauseTimer() {
    _timer!.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  // This function unfortunately has to be called everytime we change _remainingTime
  // I'm sure there's a better way to do this.
  void _updateTextFields() { 
    _minutesController.text = (_remainingTime ~/ 60).toString().padLeft(2, '0');
    _secondsController.text = (_remainingTime % 60).toString().padLeft(2, '0');
  }

  void _updateRemainingTime() {
    int newMinutes = int.tryParse(_minutesController.text) ?? 0;
    int newSeconds = int.tryParse(_secondsController.text) ?? 0;
    _remainingTime = newMinutes * 60 + newSeconds;
    _initialTime = _remainingTime;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _minutesController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.displayLarge,
                readOnly: _isTimerRunning ? true : false,
                onTapOutside: (event) {
                  _updateRemainingTime();
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              ),
            ),
            Text(':', style: Theme.of(context).textTheme.displayLarge),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _secondsController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.displayLarge,
                readOnly: _isTimerRunning ? true : false,
                onTapOutside: (event) {
                  _updateRemainingTime();
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64.0,
              height: 64.0,
              child: IconButton(
                icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 48.0),
                onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
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
          ],
        ),
      ],
    );
  }
}
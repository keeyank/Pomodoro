import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
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
  int focusTime = 25 * 60;  // Default 25 minutes
  int breakTime = 5 * 60;   // Default 5 minutes

  int get currentTime {
    return mode == Mode.focus ? focusTime : breakTime;
  }

  void toggleMode() {
    mode = mode == Mode.focus ? Mode.chill : Mode.focus;
    notifyListeners();
  }

  void updateTimes(int newFocusTime, int newBreakTime) {
    focusTime = newFocusTime;
    breakTime = newBreakTime;
    notifyListeners();
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


class PomodoroPage extends StatelessWidget {
  final String title;

  PomodoroPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Consumer<PomodoroMode>(
                  builder: (context, pomodoroMode, child) => Text(
                    pomodoroMode.mode == Mode.focus ? 'Focus Time' : 'Break Time',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Pomodoro(),
            ),
          ),
        ],
      ),
    );
  }
}

class Pomodoro extends StatefulWidget {
  Pomodoro();

  @override
  _PomodoroState createState() => _PomodoroState();
}

class _PomodoroState extends State<Pomodoro> {
  late int _remainingTime;
  Timer? _timer;

  late bool _isTimerRunning = false;

  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _updateTimerDuration();
    _updateTextFields();
  }

  void _updateTimerDuration() {
    _remainingTime = Provider.of<PomodoroMode>(context, listen: false).currentTime;
    _updateTextFields();
  }

  Future<void> _playSound() async {
    await player.play(AssetSource('timer-sound.mp3'));
  }

    Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000);
    }
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
          _changeMode();
          _playSound();
          _vibrate();
        }
      });
    });
  }

   void _pauseTimer() {
    _timer!.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _changeMode() {
    _pauseTimer();
    context.read<PomodoroMode>().toggleMode();
    _updateTimerDuration();
    _updateTextFields();
  }

  void _resetTimer() {
    _updateTimerDuration();
    _updateTextFields();
    _startTimer();
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
        Image.asset(
          'assets/tomato.png',
          width: 130,
          height: 130,
        ),
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
                  _updateTextFields();
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
                  _updateTextFields();
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
            SizedBox(
              width: 64.0,
              height: 64.0,
              child: IconButton(
                icon: Icon(Icons.skip_next, size: 48.0),
                onPressed: _changeMode,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Text('Settings page placeholder'),
      ),
    );
  }
}
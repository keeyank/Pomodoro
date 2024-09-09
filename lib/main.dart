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

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

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
        navigatorObservers: [routeObserver],
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

class _PomodoroState extends State<Pomodoro> with RouteAware {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (!_isTimerRunning && _remainingTime % 60 == 0) {
      _updateTimerDuration();
    }
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
    if (_timer != null) {
      _timer!.cancel();   
    }
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _changeMode() {
    _pauseTimer();
    context.read<PomodoroMode>().toggleMode();
    _updateTimerDuration();
  }

  void _resetTimer() {
    _updateTimerDuration();
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

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _focusTimeController = TextEditingController();
  final TextEditingController _breakTimeController = TextEditingController();

  String? isValidNum(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a number';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

@override
  void initState() {
    super.initState();
    final pomodoroMode = Provider.of<PomodoroMode>(context, listen: false);
    _focusTimeController.text = pomodoroMode.focusTime.toString();
    _breakTimeController.text = pomodoroMode.breakTime.toString();
  }

  @override
  void dispose() {
    _focusTimeController.dispose();
    _breakTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroMode = Provider.of<PomodoroMode>(context, listen: false);
    _focusTimeController.text = (pomodoroMode.focusTime ~/ 60).toString();
    _breakTimeController.text = (pomodoroMode.breakTime ~/ 60).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _focusTimeController,
                decoration: InputDecoration(labelText: 'Focus Time (minutes)'),
                keyboardType: TextInputType.number,
                validator: isValidNum,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _breakTimeController,
                decoration: InputDecoration(labelText: 'Break Time (minutes)'),
                keyboardType: TextInputType.number,
                validator: isValidNum,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    int newFocusTime = int.parse(_focusTimeController.text);
                    int newBreakTime = int.parse(_breakTimeController.text);
                    Provider.of<PomodoroMode>(context, listen: false).updateTimes(
                      newFocusTime * 60, 
                      newBreakTime * 60
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttering',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: const Color.fromARGB(255, 183, 58, 58)),
        focusColor: Colors.blue,
        appBarTheme: AppBarTheme(
          
        )
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page', subtitle: 'Flutter Demo Home Page 2'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.subtitle});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String subtitle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Column(
          children: [
            Text(widget.title),
            Text(widget.subtitle),
          ],
        ),
        //subtitle: Text(widget.subtitle),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('Dialing'),
            // // Image.asset(
            //   'assets/images/JOHNPORK.png',
            //   width: 200,
            //   height: 200,
            // ),
            CircleAvatar(
              radius: 100, // Sets the size of the circle
              backgroundImage: AssetImage('assets/images/JOHNPORK.png'),
            ),
            Text(
              'John Pork',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('+1111-2222-3333'),
            Divider(
              color: const Color.fromARGB(255, 100, 99, 99),
              height: 10.0,
              //width: 300.0,
            ),
            Container( 
              color: Color.fromARGB(0, 255, 0, 0),
              child: Column(
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        color: Color.fromARGB(255, 71, 69, 69),
                      ),
                      Text('Mute'),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.bluetooth_rounded,
                        color: Color.fromARGB(255, 71, 69, 69),
                      ),
                      Text('Bluetooth'),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.phone_paused_rounded,
                        color: Color.fromARGB(255, 71, 69, 69),
                      ),
                      Text('Hold'),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.window_rounded,
                        color: Color.fromARGB(255, 71, 69, 69),
                      ),
                      //Text('Mute'),
                    ],
                  ),
                  Column(
                    children: [
                      CircleAvatar(
              radius: 30, // Sets the size of the circle
              backgroundImage: AssetImage('assets/images/phoneicon.png'),
            ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.speaker_rounded,
                        color: Color.fromARGB(255, 71, 69, 69),
                      ),
                      //Text('Hold'),
                    ],
                  ),
                ],
              ),
              
              ],
              ),
            )
            
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.minor_crash_outlined),
      // ),
    );
  }
}

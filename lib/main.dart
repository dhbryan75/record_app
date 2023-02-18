//import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakaomap_webview/kakaomap_webview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class CustomTextInput extends StatelessWidget {
  const CustomTextInput({
    super.key,
    required this.width,
    required this.labelText,
    required this.textController,
    required this.keyboardType,
    required this.minLines,
    required this.maxLines,
  });

  final double width;
  final String labelText;
  final TextEditingController textController;
  final TextInputType keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        margin: const EdgeInsets.all(5),
        child: TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: labelText,
          ),
          textAlign: TextAlign.center,
          controller: textController,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: 5,
        ));
  }
}

//https://developers.kakao.com/console/app/864339
const String kakaoMapKey = '9d5ef64973f9061b58614170830a2cb3';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  Position? position;
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future initializeNotificationPlugin() async {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    await showNotification();
  }

  Future showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails("reminder", "리마인더",
            channelDescription: "리마인더: 기록하세요",
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true);
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        "REMINDER",
        "",
        RepeatInterval.hourly,
        //RepeatInterval.everyMinute,
        platformChannelSpecifics,
        androidAllowWhileIdle: true);
  }

  Future getPosition() async {
    setState(() {
      position = null;
    });
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position newPosition = await Geolocator.getCurrentPosition();
    setState(() {
      position = newPosition;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeNotificationPlugin();
    getPosition();
  }

  @override
  Widget build(BuildContext context) {
    Widget component;
    if (position != null) {
      Size size = MediaQuery.of(context).size;
      double textInputW = size.width * 0.8;
      double mapW = size.width;
      double mapH = size.height * 0.3;

      component = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          KakaoMapView(
            width: mapW,
            height: mapH,
            kakaoMapKey: kakaoMapKey,
            lat: position?.latitude ?? 133,
            lng: position?.longitude ?? 60,
            zoomLevel: 2,
            showMapTypeControl: false,
            showZoomControl: false,
          ),
          CustomTextInput(
            width: textInputW,
            labelText: "제목",
            textController: titleTextController,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 1,
          ),
          CustomTextInput(
            width: textInputW,
            labelText: "내용",
            textController: contentTextController,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 5,
          ),
          ElevatedButton(
              onPressed: () {
                print(
                    '${titleTextController.text} ${contentTextController.text}');
              },
              child: const Text('완료'))
        ],
      );
    } else {
      component = const Center(
          child: Text("Loading...", style: TextStyle(fontSize: 25)));
    }

    return Scaffold(
      body: SafeArea(child: component),
      floatingActionButton: FloatingActionButton(
        onPressed: getPosition,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

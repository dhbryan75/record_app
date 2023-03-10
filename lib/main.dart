import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakaomap_webview/kakaomap_webview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

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
  final placeTextController = TextEditingController();
  final personTextController = TextEditingController();
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

  Future resetNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
    await showNotification();
    toast("알림 리셋 완료");
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
    toast("위치 새로고침 완료");
  }

  void toast(message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void alert(title, content) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("확인"))
              ],
            ));
  }

  Future postRecord(latitude, longitude, place, person, title, content) async {
    var url = Uri.http('3.37.230.24', 'api/record');
    var body = json.encode({
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'place': place,
      'person': person,
      'title': title,
      'content': content,
    });
    var response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: body);
    if (response.statusCode == 200) {
      toast("기록 완료");
    } else {
      alert('${response.statusCode}', response.body);
    }
  }

  @override
  void initState() {
    super.initState();
    initializeNotificationPlugin();
    getPosition();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (position != null) {
      Size size = MediaQuery.of(context).size;
      double textInputW = size.width * 0.8;
      double textInputHalfW = size.width * 0.35;
      double mapW = size.width;
      double mapH = size.height * 0.3;

      body = Stack(children: [
        Column(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                CustomTextInput(
                  width: textInputHalfW,
                  labelText: "장소",
                  textController: placeTextController,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                ),
                const Spacer(),
                CustomTextInput(
                  width: textInputHalfW,
                  labelText: "사람",
                  textController: personTextController,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                ),
                const Spacer(),
              ],
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
                  if (titleTextController.text == "") {
                    toast("제목이 비어있음");
                    return;
                  }
                  postRecord(
                      position?.latitude,
                      position?.longitude,
                      placeTextController.text,
                      personTextController.text,
                      titleTextController.text,
                      contentTextController.text);

                  placeTextController.clear();
                  personTextController.clear();
                  titleTextController.clear();
                  contentTextController.clear();
                },
                style: ElevatedButton.styleFrom(primary: Colors.deepOrange),
                child: const Text(
                  '완료',
                  style: TextStyle(fontSize: 18),
                )),
          ],
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: resetNotification,
            backgroundColor: Colors.green,
            child: const Icon(Icons.notifications),
          ),
        )
      ]);
    } else {
      body = const Center(
          child: Text("Loading...", style: TextStyle(fontSize: 25)));
    }

    return Scaffold(
      body: SafeArea(child: body),
      floatingActionButton: FloatingActionButton(
        onPressed: getPosition,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

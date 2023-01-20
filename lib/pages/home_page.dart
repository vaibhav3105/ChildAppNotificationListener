import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'package:forground_app/pages/first_task_handler.dart';

import 'package:notification_listener_service/notification_listener_service.dart';

import 'package:platform_device_id/platform_device_id.dart';

// The callback function should always be a top-level function.

@pragma("vm:entry-point")
void startCallback() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  String? id = await PlatformDeviceId.getDeviceId;

  FlutterForegroundTask.setTaskHandler(
    FirstTaskHandler(
      FirebaseAuth.instance.currentUser!.uid,
      id!,
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final childNameController = TextEditingController();
  String deviceId = "";
  String childName = "";
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // iconData: const NotificationIconData(
        //   resType: ResourceType.mipmap,
        //   resPrefix: ResourcePrefix.ic,
        //   name: 'launcher',
        // ),
        // buttons: [
        //   const NotificationButton(id: 'sendButton', text: 'Send'),
        //   const NotificationButton(id: 'testButton', text: 'Test'),
        // ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> _startForegroundTask() async {
    bool reqResult;
    if (await FlutterForegroundTask.isRunningService) {
      reqResult = await FlutterForegroundTask.restartService();
    } else {
      reqResult = await FlutterForegroundTask.startService(
        notificationTitle: '',
        notificationText: '',
        callback: startCallback,
      );
    }

    if (reqResult) {
      return true;
    }

    return false;
  }

  Future<bool> _stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  getId() async {
    String? DeviceId = await PlatformDeviceId.getDeviceId;

    setState(() {
      deviceIdController.text = DeviceId!;
      childNameController.text = DeviceId;
      deviceId = DeviceId;
    });
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    getId();
    getInfoAboutChildName();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getInfoAboutChildName() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    List existingChildren = doc.get("children");
    for (var i = 0; i < existingChildren.length; i++) {
      Map map = existingChildren[i];
      if (map.containsValue(deviceId)) {
        setState(() {
          childName = map["childName"];
        });
        break;
      }
    }
  }

  final deviceIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Child App'),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 30,
              ),
              _buildContentView(),
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Device ID:",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: deviceIdController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              if (childName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Child Name:",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        "$childName",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              if (childName.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: childNameController,
                    decoration: InputDecoration(
                      hintText: "Enter Child Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: 50,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () async {
                    DocumentSnapshot doc = await FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .get();
                    bool idExists = false;
                    List existingChildren = doc.get("children");
                    for (var i = 0; i < existingChildren.length; i++) {
                      Map map = existingChildren[i];
                      if (map.containsValue(deviceId)) {
                        idExists = true;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "This Device id already exists",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                        break;
                      }
                    }
                    if (!idExists &&
                        childNameController.text.trim().isNotEmpty) {
                      existingChildren.add(
                        {
                          'deviceId': deviceIdController.text.trim(),
                          "childName": childNameController.text.trim(),
                        },
                      );
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .update({"children": existingChildren});
                      Future.delayed(Duration(seconds: 3));
                      setState(() {
                        childName = childNameController.text.trim();
                      });
                    } else if (!idExists &&
                        childNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Child Name cannot be empty")));
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color.fromARGB(255, 6, 113, 221),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      "Save Child Name",
                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () async {
                await FlutterOverlayWindow.requestPermission();
                await NotificationListenerService.requestPermission();
              },
              child: Container(
                alignment: Alignment.center,
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color.fromARGB(255, 6, 113, 221),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Image.asset(
                      "assets/switch.png",
                      height: 40,
                      width: 40,
                    ),
                    Text(
                      "Request Permissions",
                      style: TextStyle(fontSize: 26),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTestButton(
                    'Start Listening',
                    Image.asset(
                      "assets/play-button.png",
                      height: 35,
                      width: 35,
                      color: Colors.green,
                    ),
                    onPressed: _startForegroundTask),
                _buildTestButton(
                    'Stop Listening',
                    Image.asset(
                      "assets/pause.png",
                      height: 35,
                      width: 35,
                      color: Colors.red,
                    ),
                    onPressed: _stopForegroundTask),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, Widget icon, {VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(4),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 2.5,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color.fromARGB(255, 6, 113, 221),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                text,
                style: TextStyle(fontSize: 25),
              ),
              icon
            ],
          ),
        ),
      ),
    );
  }
}

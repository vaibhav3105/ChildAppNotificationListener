import 'dart:async';
import 'dart:convert';

import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:notification_listener_service/notification_event.dart';

import 'package:notification_listener_service/notification_listener_service.dart';

class FirstTaskHandler extends TaskHandler {
  final String uid;
  final String id;

  String rulesReloadDate = DateTime.now().toString().substring(0, 10);

  FirstTaskHandler(this.uid, this.id);
  String encode(String message) {
    String encoded = base64Encode(utf8.encode(message));
    return encoded;
  }

  bool isRuleMatch(rule, ServiceNotificationEvent event) {
    if (event.packageName == rule['packageName']) {
      if (rule['title'].toString().isNotEmpty) {
        if (event.title == rule['title']) {
          List bodyKeys = rule['keys'];
          if (bodyKeys.length > 0 && bodyKeys[0].toString().isNotEmpty) {
            bool result = false;
            bodyKeys.forEach((element) {
              if (event.content!.contains(element) &&
                  element.toString().isNotEmpty) {
                result = true;
              }
            });
            return result;
          } else {
            return true;
          }
        } else {
          return false;
        }
      } else {
        List bodyKeys = rule['keys'];
        if (bodyKeys.length > 0 && bodyKeys[0].toString().isNotEmpty) {
          bool result = false;
          bodyKeys.forEach((element) {
            if (event.content!.contains(element) &&
                element.toString().isNotEmpty) {
              result = true;
            }
          });
          return result;
        } else {
          return true;
        }
      }
    } else {
      return false;
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    await Firebase.initializeApp();

    List rules = [];
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    rules = await doc.get("rules") as List<dynamic>;
    print(rules);
    rulesReloadDate = DateTime.now().toString().substring(0, 10);
    print(rulesReloadDate);

    NotificationListenerService.notificationsStream.listen((event) async {
      if (DateTime.now().toString().substring(0, 10) != rulesReloadDate) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection("users").doc(uid).get();

        rules = await doc.get("rules") as List<dynamic>;
        print(rules);
        rulesReloadDate = DateTime.now().toString().substring(0, 10);
      }

      for (var i = 0; i < rules.length; i++) {
        if (isRuleMatch(rules[i], event)) {
          FirebaseFirestore.instance
              .collection("data")
              .doc(uid)
              .collection("messages")
              .add({
            "package": event.packageName.toString(),
            "title": event.title.toString(),
            "content": encode(event.content.toString()),
            "time": DateTime.now().toString(),
            "child": id
          });
        }
      }
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}

  @override
  void onButtonPressed(String id) {}
}

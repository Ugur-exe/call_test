// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:flutter_callkeep_example/app_router.dart';
import 'package:flutter_callkeep_example/navigation_service.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  late final Uuid _uuid;
  String? _currentUuid;
  String textEvents = "";

  @override
  void initState() {
    super.initState();
    _uuid = const Uuid();
    _currentUuid = "";
    textEvents = "";
    initCurrentCall();
    setEventHandler(onEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Robot Uyarı Uygulaması'),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          if (textEvents.isNotEmpty) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Text(textEvents),
              ),
            );
          } else {
            return const Center(
              child: Text('No Event'),
            );
          }
        },
      ),
    );
  }

  initCurrentCall() async {
    var calls = await CallKeep.instance.activeCalls();
    if (calls.isNotEmpty) {
      print('DATA: $calls');
      _currentUuid = calls[0].uuid;
      return calls[0];
    }
  }

  Future<void> makeFakeCallInComing(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 10), () async {
      _currentUuid = _uuid.v4();

      final data = CallEvent(
        uuid: _currentUuid ?? '',
        callerName: 'Hien Nguyen',
        handle: '0123456789',
        duration: 30000,
        hasVideo: true,
        extra: <String, dynamic>{'userId': '1a2b3c4d'},
      );

      await CallKeep.instance.displayIncomingCall(data, context: context);
    });
  }

  Future<void> setEventHandler(Function? callback) async {
    CallKeep.instance.handler = CallEventHandler(
      onCallIncoming: (event) {
        print('call incoming: ${event.toMap()}');
        if (!CallKeep.instance.isIncomingCallDisplayed) {
          showAdaptiveDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Incoming Call"),
                  content: Text("Incoming call from ${event.callerName}"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        CallKeep.instance.acceptCall(event.uuid);
                        Navigator.pop(context);
                      },
                      child: const Text("Accept"),
                    ),
                    TextButton(
                      onPressed: () {
                        CallKeep.instance.endCall(event.uuid);
                        Navigator.pop(context);
                      },
                      child: const Text("Decline"),
                    ),
                  ],
                );
              });
        }
        if (callback != null) callback.call(event, "incoming");
      },
      onCallStarted: (event) {
        print('call started: ${event.toMap()}');
        if (callback != null) callback.call(event, "outgoing");
      },
      onCallEnded: (event) {
        print('call ended: ${event.toMap()}');
        if (callback != null) callback.call(event, "ended");
      },
      onCallAccepted: (event) {
        print('call answered: ${event.toMap()}');
        NavigationService.instance
            .pushNamedIfNotCurrent(AppRoute.callingPage, args: event.toMap());
        if (callback != null) callback.call(event, "accepted");
      },
      onCallDeclined: (event) async {
        print('call declined: ${event.toMap()}');
        if (callback != null) callback.call(event, "declined");
      },
    );
  }

  onEvent(event, type) {
    if (!mounted) return;
    setState(() {
      textEvents += "$type: ${event.toString()}\n";
    });
  }
}

import 'package:flutter/material.dart';
import 'package:google_cast/discovery_criteria.dart/discovery_criteria.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'dart:async';
import 'package:google_cast/google_cast.dart';
import 'package:google_cast/google_cast_context/google_cast_context.dart';
import 'package:google_cast/google_cast_context/google_cast_context_method_channel.dart';
import 'package:google_cast/google_cast_options/ios_cast_options.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _googleCastPlugin = GoogleCast();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    FlutterGoogleCastContext.setSharedInstanceWithOptions(IOSGoogleCastOptions(
      GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
        AGoogleCastDiscoveryCriteria.kDefaultApplicationId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: StreamBuilder<List<GoogleCastDevice>>(
            stream:
                FlutterIOSGoogleCastContextMethodChannel.instance.devicesStream,
            builder: (context, snapshot) {
              final devices = snapshot.data ?? [];
              return ListView(
                children: [
                  ...devices.map((device) {
                    return ListTile(
                      title: Text(device.friendlyName),
                      subtitle: Text(device.modelName ?? ''),
                      onTap: () async {
                        FlutterIOSGoogleCastContextMethodChannel
                            .instance.sessionManager
                            .startSessionWithDevice(device);
                      },
                    );
                  })
                ],
              );
            },
          )),
    );
  }
}

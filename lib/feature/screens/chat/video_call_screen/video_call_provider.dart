import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallProvider extends ChangeNotifier {
  late RtcEngine engine; // ✅ FIXED

  int? remoteUid;
  int seconds = 0;
  Timer? timer;

  bool isInitialized = false; // ✅ loading state
  bool isMuted = false;

  final String appId = "f118eaa02058464a89f75be49b7aa0a4";

  Future<void> initAgora(String channelName) async {
    await [Permission.microphone, Permission.camera].request();

    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, uid, elapsed) {
          remoteUid = uid;

          startTimer(); // ✅ start timer when user joins
          notifyListeners();
        },
        onUserOffline: (connection, uid, reason) {
          remoteUid = null;

          timer?.cancel(); // ✅ stop timer
          notifyListeners();
        },
      ),
    );

    await engine.enableVideo();
    await engine.startPreview();

    await engine.joinChannel(
      token: "",
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );

    isInitialized = true; // ✅ VERY IMPORTANT
    notifyListeners();
  }

  /// 🔥 TIMER FUNCTION
  void startTimer() {
    timer?.cancel();
    seconds = 0;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      notifyListeners();
    });
  }

  void toggleMute() {
    isMuted = !isMuted;
    engine.muteLocalAudioStream(isMuted);
    notifyListeners();
  }

  void switchCamera() {
    engine.switchCamera();
  }

  Future<void> endCall() async {
    timer?.cancel();
    seconds = 0;

    await engine.leaveChannel();
    await engine.release();
  }
}

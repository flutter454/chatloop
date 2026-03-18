import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;

  const VideoCallScreen({super.key, required this.channelName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  int? _remoteUid;

  final String appId = "f118eaa02058464a89f75be49b7aa0a4";

  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, uid, elapsed) {
          setState(() {
            _remoteUid = uid;
          });
        },
        onUserOffline: (connection, uid, reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: null ?? '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
    _engine.muteLocalAudioStream(isMuted);
  }

  void switchCamera() {
    _engine.switchCamera();
  }

  void endCall() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 🔥 Remote Video
          Center(
            child: _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : const Text(
                    "Waiting for user...",
                    style: TextStyle(color: Colors.white),
                  ),
          ),

          /// 🔥 Local Video (small)
          Positioned(
            top: 40,
            right: 20,
            child: SizedBox(
              width: 120,
              height: 160,
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),

          /// 🔥 Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// Mute
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: Icon(
                      isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                    onPressed: toggleMute,
                  ),
                ),

                /// End Call
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    onPressed: endCall,
                  ),
                ),

                /// Switch Camera
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: switchCamera,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

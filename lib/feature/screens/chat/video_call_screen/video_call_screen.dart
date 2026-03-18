import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'video_call_provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String? callerImage;
  final String? callerName;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    this.callerImage,
    this.callerName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<VideoCallProvider>().initAgora(widget.channelName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoCallProvider>();

    /// ⏱ Format Timer
    String formatTime(int seconds) {
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      return "$minutes:$secs";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 🔥 Remote Video
          Center(
            child: provider.remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: provider.engine,
                      canvas: VideoCanvas(uid: provider.remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, color: Colors.white54, size: 60),
                      SizedBox(height: 10),
                      Text(
                        "Waiting for user...",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
          ),

          /// 🔥 Call Timer
          Positioned(
            top: 40,
            left: 20,
            child: Text(
              formatTime(provider.seconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// 🔥 Top Info (Profile + Name)
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: widget.callerImage != null
                      ? NetworkImage(widget.callerImage!)
                      : null,
                  child: widget.callerImage == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.callerName ?? "Unknown",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Video Call",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 🔥 Local Video (small preview)
          Positioned(
            top: 140,
            right: 20,
            child: SizedBox(
              width: 120,
              height: 160,
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: provider.engine,
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
                /// 🎤 Mute
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: Icon(
                      provider.isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                    onPressed: provider.toggleMute,
                  ),
                ),

                /// 🔴 End Call
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    onPressed: () async {
                      await provider.endCall();
                      Navigator.pop(context);
                    },
                  ),
                ),

                /// 🔄 Switch Camera
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: provider.switchCamera,
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

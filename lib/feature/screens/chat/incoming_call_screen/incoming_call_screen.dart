import 'package:flutter/material.dart';

class IncomingCallScreen extends StatelessWidget {
  final Map callData;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallScreen({
    super.key,
    required this.callData,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),

            // Caller Info
            Column(
              children: [
                const Text(
                  "Incoming Call",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 20),

                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),

                const SizedBox(height: 20),

                Text(
                  callData['caller_id'], // You can replace with name later
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject
                  Column(
                    children: [
                      GestureDetector(
                        onTap: onReject,
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.call_end, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Decline",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),

                  // Accept
                  Column(
                    children: [
                      GestureDetector(
                        onTap: onAccept,
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.green,
                          child: Icon(Icons.call, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Accept",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

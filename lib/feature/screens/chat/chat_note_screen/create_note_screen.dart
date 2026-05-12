import 'package:chatloop/feature/screens/chat/chat_note_screen/song_selection_screen.dart';
import 'package:flutter/material.dart';

class CreateNoteScreen extends StatefulWidget {
  final String initialNote;
  final String userPhotoUrl;
  final Function(String) onSave;
  final Function(Map<String, String>?) onSongSelected;

  const CreateNoteScreen({
    super.key,
    required this.initialNote,
    required this.userPhotoUrl,
    required this.onSave,
    required this.onSongSelected,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  late TextEditingController _controller;
  Map<String, String>? _selectedSong;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 30,
                      color: Color.fromRGBO(0, 0, 0, 1),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "New Note", // Fallback title or remove if strictly following screenshot looking for "Color Wheel"
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // Placeholder for the "Color Wheel" icon or Save text if preferred
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    // If we want a color wheel effect
                    child: const Icon(
                      Icons.color_lens_outlined,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main Content
                  SingleChildScrollView(
                    // To handle keyboard pushing up
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Thought Bubble
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _controller,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: null,
                                  maxLength: 60,
                                  decoration: InputDecoration(
                                    hintText: _selectedSong != null
                                        ? '${_selectedSong!['title']} \n ${_selectedSong!['artist']}'
                                        : 'Share a thought...',
                                    border: InputBorder.none,
                                    counterText: "", // Hide counter
                                  ),
                                ),
                              ),
                              // Little triangle for the bubble
                              Positioned(
                                bottom: -10,
                                child: CustomPaint(
                                  painter: TrianglePainter(color: Colors.white),
                                  size: const Size(20, 10),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // User Avatar
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: NetworkImage(widget.userPhotoUrl),
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons (Music, Location)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(Icons.music_note, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SongSelectionScreen(
                                    onSongSelected: (song) {
                                      setState(() {
                                        _selectedSong = song;
                                      });
                                    },
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(width: 16),
                            _buildActionButton(
                              Icons.location_on_outlined,
                              () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer (Share buttons)
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    10, // Adjust for keyboard
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            "Share with friends",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(_controller.text);
                      widget.onSongSelected(_selectedSong);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFC6C6FF,
                      ), // Light purple/blue
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Share",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.purple),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color;
    var path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

import 'package:flutter/material.dart';

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFFF4081)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF4081), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class ProfileDropdownField extends StatelessWidget {
  final String? value;
  final String hintText;
  final IconData prefixIcon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const ProfileDropdownField({
    super.key,
    required this.value,
    required this.hintText,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFFF4081)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF4081), width: 1.5),
        ),
      ),
    );
  }
}

class SlideToActionButton extends StatefulWidget {
  final String text;
  final VoidCallback onAction;
  final Widget? icon;
  final Color baseColor;
  final Color actionColor;
  final bool enabled;

  const SlideToActionButton({
    super.key,
    required this.text,
    required this.onAction,
    this.icon,
    this.baseColor = Colors.white,
    this.actionColor = const Color(0xFFFF4081),
    this.enabled = true,
  });

  @override
  State<SlideToActionButton> createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with SingleTickerProviderStateMixin {
  double _position = 0;
  final double _buttonHeight = 60;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double handleSize = _buttonHeight - 8;
        final double maxScroll = maxWidth - handleSize - 8;

        final Color currentBaseColor = widget.enabled
            ? widget.baseColor
            : Colors.grey.shade100;
        final Color currentActionColor = widget.enabled
            ? widget.actionColor
            : Colors.grey.shade300;
        final Color currentTextColor = widget.enabled
            ? Colors.black54
            : Colors.grey.shade400;

        return Container(
          height: _buttonHeight,
          decoration: BoxDecoration(
            color: currentBaseColor,
            borderRadius: BorderRadius.circular(_buttonHeight / 2),
            border: Border.all(
              color: widget.enabled
                  ? Colors.grey.shade300
                  : Colors.grey.shade400,
            ),
            boxShadow: [
              if (widget.enabled)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: (1 - (_position / maxScroll)).clamp(0.2, 1.0),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: widget.enabled
                                ? [
                                    Colors.black54,
                                    Colors.pinkAccent,
                                    Colors.black54,
                                  ]
                                : [Colors.grey, Colors.grey, Colors.grey],
                            stops: [
                              _animationController.value - 0.2,
                              _animationController.value,
                              _animationController.value + 0.2,
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            color: widget.enabled
                                ? Colors.white
                                : currentTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: _position + 4,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!widget.enabled) return;
                    setState(() {
                      _position = (_position + details.delta.dx).clamp(
                        0.0,
                        maxScroll,
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!widget.enabled) return;
                    if (_position >= maxScroll * 0.8) {
                      setState(() {
                        _position = maxScroll;
                      });
                      widget.onAction();
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (mounted) {
                          setState(() {
                            _position = 0;
                          });
                        }
                      });
                    } else {
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: handleSize,
                        height: handleSize,
                        decoration: BoxDecoration(
                          color: currentActionColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (widget.enabled)
                              BoxShadow(
                                color: widget.actionColor.withOpacity(0.3),
                                blurRadius: 8 * _animationController.value,
                                spreadRadius: 4 * _animationController.value,
                              ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child:
                              widget.icon ??
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

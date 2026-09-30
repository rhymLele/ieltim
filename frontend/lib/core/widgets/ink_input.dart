import 'package:flutter/material.dart';

const _wine = Color(0xFF7A001A);
const _wineFaint = Color(0x247A001A); // wine at ~14% opacity

/// Access-key field: no box, just a faint line.
/// On focus, a wine-colored line spreads out from the center.
class InkLineField extends StatefulWidget {
  const InkLineField({
    super.key,
    required this.controller,
    this.hint = 'Enter your access key',
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  @override
  State<InkLineField> createState() => _InkLineFieldState();
}

class _InkLineFieldState extends State<InkLineField> {
  final _focus = FocusNode();
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: _hidden,
          cursorColor: _wine,
          style: const TextStyle(fontSize: 16),
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            prefixIcon: const Icon(Icons.vpn_key_outlined, color: _wine),
            suffixIcon: IconButton(
              tooltip: _hidden ? 'Show key' : 'Hide key',
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.black45,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
          ),
        ),
        // Faint resting line
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 1.5,
          child: ColoredBox(color: _wineFaint),
        ),
        // Wine line that spreads from the center on focus
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 2.5,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            widthFactor: _focus.hasFocus ? 1 : 0,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: _wine,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Usage:
// final _keyCtrl = TextEditingController();
// ...
// InkLineField(controller: _keyCtrl, onSubmitted: (_) => _submit()),

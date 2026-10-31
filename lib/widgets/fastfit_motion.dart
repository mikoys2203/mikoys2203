import 'package:flutter/material.dart';

/// FastFit's shared visual language. Animations are deliberately subtle;
/// controls retain Material keyboard, focus, tooltip and screen-reader support.
class FastFitStyle {
  static const red = Color(0xFFCF252D);
  static const deepRed = Color(0xFFAA1E28);
  static const ink = Color(0xFF20242B);
  static const muted = Color(0xFF69717D);
  static const surface = Color(0xFFFAF8F6);
  static const line = Color(0xFFE8E4E1);
  static const softRed = Color(0xFFFFEEEE);
  static const warmWhite = Color(0xFFFFFCFA);
  static const green = Color(0xFF268B64);

  static InputDecoration field(String label, IconData icon,
      {String? hint, Widget? suffix}) {
    OutlineInputBorder outline(Color color, double width) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: color, width: width));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 21, color: muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: outline(line, 1),
      enabledBorder: outline(line, 1),
      focusedBorder: outline(red, 1.8),
      errorBorder: outline(deepRed, 1.2),
      focusedErrorBorder: outline(deepRed, 1.8),
      disabledBorder: outline(line, 1),
    );
  }
}

class FastFitButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;
  final bool fillWidth;
  const FastFitButton({super.key, required this.label, required this.onPressed,
    this.icon, this.loading = false, this.outlined = false,
    this.fillWidth = false});
  @override
  State<FastFitButton> createState() => _FastFitButtonState();
}

class _FastFitButtonState extends State<FastFitButton> {
  bool hovered = false;
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final active = enabled && hovered;
    final button = widget.outlined
      ? OutlinedButton(
          onPressed: enabled ? widget.onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: FastFitStyle.deepRed,
            minimumSize: Size(widget.fillWidth ? double.infinity : 128, 52),
            side: const BorderSide(color: FastFitStyle.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          child: _content())
      : FilledButton(
          onPressed: enabled ? widget.onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: FastFitStyle.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE7ABAE),
            minimumSize: Size(widget.fillWidth ? double.infinity : 128, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          child: _content());
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() { hovered = false; pressed = false; }),
      child: Listener(
        onPointerDown: (_) { if (enabled) setState(() => pressed = true); },
        onPointerUp: (_) { if (mounted) setState(() => pressed = false); },
        onPointerCancel: (_) { if (mounted) setState(() => pressed = false); },
        child: AnimatedScale(
          scale: !enabled ? 1 : pressed ? 0.985 : active ? 1.012 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 190),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              boxShadow: widget.outlined || !enabled ? [] : [
                BoxShadow(color: FastFitStyle.red.withValues(
                  alpha: active ? 0.21 : 0.10),
                  offset: Offset(0, active ? 7 : 4),
                  blurRadius: active ? 17 : 10),
              ],
            ),
            child: button,
          ),
        ),
      ),
    );
  }

  Widget _content() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 180),
    child: widget.loading
      ? SizedBox(key: const ValueKey('loading'), height: 21, width: 21,
          child: CircularProgressIndicator(strokeWidth: 2.3,
            color: widget.outlined ? FastFitStyle.red : Colors.white))
      : Row(key: const ValueKey('label'), mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(widget.label, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14)),
          if (widget.icon != null) ...[
            const SizedBox(width: 9), Icon(widget.icon, size: 18),
          ],
        ]),
  );
}

/// Touch-friendly, accessible option; no emoji or icon-only choices.
class FastFitChoiceCard extends StatefulWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  const FastFitChoiceCard({super.key, required this.label, this.subtitle,
    required this.icon, required this.selected, required this.onTap});
  @override
  State<FastFitChoiceCard> createState() => _FastFitChoiceCardState();
}

class _FastFitChoiceCardState extends State<FastFitChoiceCard> {
  bool hover = false;
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() { hover = false; pressed = false; }),
      child: Listener(
        onPointerDown: (_) { if (enabled) setState(() => pressed = true); },
        onPointerUp: (_) { if (mounted) setState(() => pressed = false); },
        onPointerCancel: (_) { if (mounted) setState(() => pressed = false); },
        child: AnimatedScale(
          scale: enabled && pressed ? 0.99 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: active ? FastFitStyle.softRed : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: active ? 1.7 : 1,
                color: active ? FastFitStyle.red :
                  hover ? const Color(0xFFD9BEC0) : FastFitStyle.line),
              boxShadow: hover ? [BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16, offset: const Offset(0, 6))] : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: Semantics(selected: active,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 47, width: 47,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : FastFitStyle.surface,
                          borderRadius: BorderRadius.circular(13)),
                        child: Icon(widget.icon,
                          color: active ? FastFitStyle.red : FastFitStyle.ink,
                          size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, children: [
                          Text(widget.label,
                            style: const TextStyle(fontWeight: FontWeight.w800,
                              fontSize: 14, color: FastFitStyle.ink)),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(widget.subtitle!, maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.8, height: 1.4,
                                color: FastFitStyle.muted)),
                          ],
                        ],
                      )),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 190),
                        transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          active ? Icons.check_circle_rounded :
                            Icons.radio_button_unchecked_rounded,
                          key: ValueKey(active), size: 22,
                          color: active ? FastFitStyle.red : const Color(0xFFB7B7BE)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FastFitHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const FastFitHoverCard({super.key, required this.child, this.onTap});
  @override
  State<FastFitHoverCard> createState() => _FastFitHoverCardState();
}

class _FastFitHoverCardState extends State<FastFitHoverCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() => hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          blurRadius: hover ? 22 : 8,
          color: Colors.black.withValues(alpha: hover ? 0.09 : 0.028),
          offset: Offset(0, hover ? 8 : 2))]),
      child: widget.child,
    ),
  );
}

import 'package:flutter/material.dart';
import 'fastfit_motion.dart';
import 'fastfit_brand.dart';

/// Shared, responsive sign-in/register/recovery visual shell.
/// User data forms live in the screen widgets and are not modified here.
class FastFitAuthShell extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget form;
  final bool showBack;
  const FastFitAuthShell({super.key, required this.title,
    required this.subtitle, required this.form, this.showBack = false});
  @override
  State<FastFitAuthShell> createState() => _FastFitAuthShellState();
}

class _FastFitAuthShellState extends State<FastFitAuthShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController entrance;
  @override
  void initState() {
    super.initState();
    entrance = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 480))..forward();
  }
  @override
  void dispose() { entrance.dispose(); super.dispose(); }

  Widget _brand(bool compact) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 150 : 590),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDE2D35), Color(0xFFAC1B25)]),
        borderRadius: BorderRadius.circular(compact ? 21 : 29)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(top: -90, right: -80, child: Container(
          width: compact ? 190 : 300,
          height: compact ? 190 : 300,
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .13),
              width: 40)))),
        Positioned(bottom: -155, left: -90, child: Container(
          height: 320, width: 320,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .07)))),
        Padding(
          padding: EdgeInsets.all(compact ? 24 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FastFitLogo(onDark: true, size: compact ? 39 : 46),
              SizedBox(height: compact ? 16 : 43),
              Text('Eat smart.\nMove better.\nFeel your best.',
                style: TextStyle(color: Colors.white,
                  height: 1.14, letterSpacing: -1.15,
                  fontSize: compact ? 24 : 38,
                  fontWeight: FontWeight.w900)),
              if (!compact) ...[
                const SizedBox(height: 17),
                const Text('Explore your favorite food with better nutrition insights and a fitness routine that fits you.',
                  style: TextStyle(color: Color(0xFFFFE7E7),
                    height: 1.55, fontSize: 14.5)),
                const Spacer(),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 25),
                const Row(children: [
                  _BrandFeature(icon: Icons.restaurant_menu_rounded,
                    label: 'Food'),
                  SizedBox(width: 12),
                  _BrandFeature(icon: Icons.directions_run_rounded,
                    label: 'Movement'),
                  SizedBox(width: 12),
                  _BrandFeature(icon: Icons.insights_rounded,
                    label: 'Progress'),
                ]),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _formCard() => FadeTransition(
    opacity: CurvedAnimation(parent: entrance, curve: Curves.easeOut),
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(.055, .055),
        end: Offset.zero).animate(CurvedAnimation(
          parent: entrance, curve: Curves.easeOutCubic)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FastFitStyle.line),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .035),
            offset: const Offset(0, 9), blurRadius: 28)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (widget.showBack) ...[
            Align(alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: const Text('Back to sign in'))),
            const SizedBox(height: 12),
          ],
          const Text('YOUR FASTFIT ACCOUNT', style: TextStyle(
            fontSize: 11, letterSpacing: 1.6,
            fontWeight: FontWeight.w900, color: FastFitStyle.red)),
          const SizedBox(height: 12),
          Text(widget.title,
            style: const TextStyle(fontSize: 29, letterSpacing: -.85,
              fontWeight: FontWeight.w900, color: FastFitStyle.ink)),
          const SizedBox(height: 8),
          Text(widget.subtitle, style: const TextStyle(
            fontSize: 14, height: 1.5, color: FastFitStyle.muted)),
          const SizedBox(height: 25),
          widget.form,
        ]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FastFitStyle.surface,
    body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      return Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 470 ? 14 : 24,
            vertical: wide ? 32 : 18),
          child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: SizedBox(height: 640,
                    child: _brand(false))),
                  const SizedBox(width: 30),
                  Expanded(child: _formCard()),
                ])
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 510),
                child: Column(children: [
                  _brand(true),
                  const SizedBox(height: 16),
                  _formCard(),
                ])),
        ),
      ));
    })),
  );
}

class _BrandFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BrandFeature({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(width: 5),
      Flexible(child: Text(label,
        style: const TextStyle(color: Colors.white, fontSize: 12,
          fontWeight: FontWeight.w700))),
    ]),
  );
}

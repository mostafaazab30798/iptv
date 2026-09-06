part of 'onboarding_screen.dart';

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10242D), AppColors.bg0, AppColors.bg0],
          stops: [0, 0.34, 1],
        ),
      ),
    );
  }
}

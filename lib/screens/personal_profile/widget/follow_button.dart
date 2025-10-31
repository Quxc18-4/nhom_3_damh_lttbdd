import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onPressed;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 110,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
        ),
      );
    }

    return isFollowing
        ? OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: const BorderSide(color: Colors.orange),
        minimumSize: const Size(110, 36),
      ),
      child: const Text('Hủy Follow'),
    )
        : ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(110, 36),
      ),
      child: const Text('Follow'),
    );
  }
}

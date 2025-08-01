import 'package:flutter/material.dart';

class FloatingFetchButton extends StatelessWidget {
  final void Function()? onPressed;
  final bool isLoading;

  const FloatingFetchButton({super.key, required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isLoading ? null : onPressed,
      label: isLoading
          ? Padding(
            padding: const EdgeInsets.all(4.0),
            child: const CircularProgressIndicator(color: Colors.black),
          )
          : const Text("Fetch Videos"),
      icon: isLoading ? null : const Icon(Icons.video_collection),
    );
  }
}

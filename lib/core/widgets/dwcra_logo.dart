import 'package:flutter/material.dart';

class DwcraLogo extends StatelessWidget {
  final double size;
  final bool isCircular;
  final bool isHorizontal;
  final Color? backgroundColor;

  const DwcraLogo({
    super.key,
    this.size = 100,
    this.isCircular = true,
    this.isHorizontal = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: size,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DWCRA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'CONNECT',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (isCircular) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        // Increased padding from 0.15 to 0.22 to keep logo safely inside the circle
        child: Padding(
          padding: EdgeInsets.all(size * 0.22),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } else {
      return Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
  }
}

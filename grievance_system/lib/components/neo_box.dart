import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class NeoBox extends StatelessWidget {
  final Widget? child;
  const NeoBox({required this.child,super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500,
            blurRadius: 15,
            offset: Offset(4, 4)
          ),
          BoxShadow(
              color: Colors.white,
              blurRadius: 15,
              offset: Offset(-4, -4)
          )
        ]
      ),
      padding: EdgeInsets.all(16),
      child: child,
    );
  }
}

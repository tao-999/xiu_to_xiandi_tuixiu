import 'dart:math';
import 'package:flutter/material.dart';
import 'package:newton_particles/newton_particles.dart' as np;

class SmokeEffectWidget extends StatelessWidget {
  const SmokeEffectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final random = Random();

    return np.Newton(
      effectConfigurations: List.generate(150, (i) {
        // 发射点集中在中间下方 [x≈0.45~0.55], y≈0.88~0.94
        final double x = 0.45 + random.nextDouble() * 0.1;
        final double y = 0.88 + random.nextDouble() * 0.06;

        // 发射角集中在 90 度上下微扰（纯上方）
        final double angle = 88 + random.nextDouble() * 4; // 88~92°

        return np.RelativisticEffectConfiguration(
          gravity: np.Gravity.zero,
          origin: Offset(x, y),
          maxOriginOffset: Offset(
            0.005 + random.nextDouble() * 0.005,
            0.005 + random.nextDouble() * 0.005,
          ),

          minAngle: angle,
          maxAngle: angle + 1,

          minVelocity: const np.Velocity(0.4),
          maxVelocity: const np.Velocity(1.0),

          minParticleLifespan: const Duration(seconds: 10),
          maxParticleLifespan: const Duration(seconds: 14),

          emitDuration: const Duration(milliseconds: 8),

          particleConfiguration: np.ParticleConfiguration(
            shape: np.CircleShape(),
            size: const Size(1, 1),
            color: np.LinearInterpolationParticleColor(
              colors: [
                Colors.white.withOpacity(0.006),
                Colors.white.withOpacity(0.012),
                Colors.white.withOpacity(0.018),
              ],
            ),
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// عارض ثلاثي الأبعاد تفاعلي للعضلات. يحتاج اتصال إنترنت لتحميل ملف GLB.
class BodyMuscleMap extends StatelessWidget {
  const BodyMuscleMap({
    Key? key,
    required this.activeMuscles,
    this.secondaryMuscles = const <String>[],
    this.isFrontView = true,
  }) : super(key: key);

  final List<String> activeMuscles;
  final List<String> secondaryMuscles;
  final bool isFrontView;

  // نموذج تشريحي مفتوح المصدر مشتق من BodyParts3D وZ-Anatomy.
  static const String _modelUrl =
      'https://raw.githubusercontent.com/WaterCMY/anatomy-3d/main/models/anatomy.glb';

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.threed_rotation_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  isFrontView ? 'المجسم ثلاثي الأبعاد • الأمام' : 'المجسم ثلاثي الأبعاد • الخلف',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                ModelViewer(
                  key: ValueKey<bool>(isFrontView),
                  src: _modelUrl,
                  alt: 'مجسم تفاعلي ثلاثي الأبعاد لعضلات جسم الإنسان',
                  ar: false,
                  autoRotate: true,
                  cameraControls: true,
                  disableZoom: false,
                  backgroundColor: scheme.surfaceVariant.withOpacity(0.1),
                  cameraOrbit: isFrontView ? '0deg 75deg 105%' : '180deg 75deg 105%',
                  minCameraOrbit: 'auto 15deg 70%',
                  maxCameraOrbit: 'auto 165deg 150%',
                  shadowIntensity: 0.8,
                  exposure: 1.0,
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.surface.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'اسحب لتدوير الجسم • قرّب بإصبعين للتكبير',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (activeMuscles.isNotEmpty || secondaryMuscles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _legendDot(Colors.red),
                      const SizedBox(width: 5),
                      const Text('رئيسية', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 12),
                      _legendDot(Colors.orange),
                      const SizedBox(width: 5),
                      const Text('ثانوية', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      ...activeMuscles.map((String muscle) => Chip(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.red.withOpacity(0.10),
                        side: BorderSide(color: Colors.red.withOpacity(0.22)),
                        avatar: const CircleAvatar(radius: 4, backgroundColor: Colors.red),
                        label: Text(muscle, style: const TextStyle(fontSize: 11)),
                      )),
                      ...secondaryMuscles.map((String muscle) => Chip(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.orange.withOpacity(0.10),
                        side: BorderSide(color: Colors.orange.withOpacity(0.25)),
                        avatar: const CircleAvatar(radius: 4, backgroundColor: Colors.orange),
                        label: Text(muscle, style: const TextStyle(fontSize: 11)),
                      )),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text('لم تُحدَّد عضلات لهذا التمرين',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

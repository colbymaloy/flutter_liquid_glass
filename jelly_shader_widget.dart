// import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/scheduler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SoftBody(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Flutter SoftBody',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoftBody extends StatefulWidget {
  final Widget child;
  const SoftBody({super.key, required this.child});

  @override
  State<SoftBody> createState() => _SoftBodyState();
}

class _SoftBodyState extends State<SoftBody> with SingleTickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();
  late Ticker _ticker;
  ui.Image? _snapshot;
  ui.ImageShader? _shader;

  final List<Offset> _controlPoints = [];
  final List<Offset> _vertices = [];
  final List<Offset> _originalVertices = [];
  final List<Offset> _velocities = [];
  final List<List<int>> _neighbors = [];
  final List<bool> _pinned = [];
  final int _cols = 10, _rows = 10;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    double dt = 1 / 60;
    const springK = 0.2;
    const damping = 0.85;

    for (int i = 0; i < _vertices.length; i++) {
      if (_pinned[i]) continue;
      Offset force = Offset.zero;
      for (var j in _neighbors[i]) {
        final dir = _vertices[j] - _vertices[i];
        force += dir * springK;
      }
      _velocities[i] = (_velocities[i] + force * dt) * damping;
    }
    for (int i = 0; i < _vertices.length; i++) {
      if (!_pinned[i]) _vertices[i] += _velocities[i] * dt;
    }
    setState(() {});
  }

  void _captureImage() async {
    final boundary = _childKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final shader = ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
    );
    setState(() {
      _snapshot = image;
      _shader = shader;
    });
  }

  void _generateMesh(Size size) {
    _vertices.clear();
    _originalVertices.clear();
    _velocities.clear();
    _neighbors.clear();
    _pinned.clear();
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        final pos = Offset(x * size.width / (_cols - 1), y * size.height / (_rows - 1));
        _vertices.add(pos);
        _originalVertices.add(pos);
        _velocities.add(Offset.zero);
        _pinned.add(false);
        _neighbors.add([]);
      }
    }
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        int i = y * _cols + x;
        if (x < _cols - 1) _neighbors[i].add(i + 1);
        if (x > 0) _neighbors[i].add(i - 1);
        if (y < _rows - 1) _neighbors[i].add(i + _cols);
        if (y > 0) _neighbors[i].add(i - _cols);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_vertices.isEmpty) _generateMesh(size);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_snapshot == null) _captureImage();
        });

        return GestureDetector(
          onDoubleTapDown: (details) {
            setState(() {
              _controlPoints.add(details.localPosition);
              for (int i = 0; i < _vertices.length; i++) {
                if ((_vertices[i] - details.localPosition).distance < 20) {
                  _pinned[i] = true;
                }
              }
            });
          },
          child: Stack(
            children: [
              RepaintBoundary(
                key: _childKey,
                child: widget.child,
              ),
              if (_shader != null)
                CustomPaint(
                  size: size,
                  painter: _SoftBodyPainter(
                    vertices: _vertices,
                    original: _originalVertices,
                    cols: _cols,
                    rows: _rows,
                    shader: _shader!,
                  ),
                ),
              for (int i = 0; i < _controlPoints.length; i++)
                Positioned(
                  left: _controlPoints[i].dx - 12,
                  top: _controlPoints[i].dy - 12,
                  child: GestureDetector(
                    onPanUpdate: (e) {
                      setState(() {
                        _controlPoints[i] += e.delta;
                        for (int j = 0; j < _vertices.length; j++) {
                          if ((_vertices[j] - _controlPoints[i]).distance < 20) {
                            _vertices[j] = _controlPoints[i];
                          }
                        }
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.yellow,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _SoftBodyPainter extends CustomPainter {
  final List<Offset> vertices;
  final List<Offset> original;
  final int cols, rows;
  final ui.Shader shader;

  _SoftBodyPainter({
    required this.vertices,
    required this.original,
    required this.cols,
    required this.rows,
    required this.shader,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = shader;
    for (int y = 0; y < rows - 1; y++) {
      for (int x = 0; x < cols - 1; x++) {
        int i = y * cols + x;
        final p1 = vertices[i];
        final p2 = vertices[i + 1];
        final p3 = vertices[i + cols];
        final p4 = vertices[i + cols + 1];

        canvas.drawVertices(
          ui.Vertices(
            VertexMode.triangleStrip,
            [p1, p3, p2, p4],
            textureCoordinates: [
              original[i],
              original[i + cols],
              original[i + 1],
              original[i + cols + 1],
            ],
          ),
          BlendMode.srcOver,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// import 'package:flutter/material.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Jelly Demo',
//       home: Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: Jelly(
//             child: Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Colors.cyanAccent,
//                 borderRadius: BorderRadius.circular(200),
//               ),
//               alignment: Alignment.center,
//               child: const Text(
//                 'Tap Me',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class Jelly extends StatefulWidget {
//   final Widget child;
//   final Duration duration;

//   const Jelly({
//     Key? key,
//     required this.child,
//     this.duration = const Duration(milliseconds: 600),
//   }) : super(key: key);

//   @override
//   _JellyState createState() => _JellyState();
// }

// class _JellyState extends State<Jelly> with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<double> _scaleX, _scaleY, _translateY;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(vsync: this, duration: widget.duration);
//     _scaleX = TweenSequence([
//       TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
//     ]).animate(_ctrl);
//     _scaleY = TweenSequence([
//       TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 25),
//     ]).animate(_ctrl);
//     _translateY = TweenSequence([
//       TweenSequenceItem(tween: Tween(begin: 0.0, end: 15.0), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 15.0, end: -15.0), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: -15.0, end: 8.0), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 25),
//     ]).animate(_ctrl);
//   }

//   void play() {
//     _ctrl
//       ..reset()
//       ..forward().then((_) => _ctrl.reverse());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: play,
//       child: AnimatedBuilder(
//         animation: _ctrl,
//         builder: (context, child) {
//           return Transform.translate(
//             offset: Offset(0, _translateY.value),
//             child: Transform.scale(
//               scaleX: _scaleX.value,
//               scaleY: _scaleY.value,
//               child: child,
//             ),
//           );
//         },
//         child: widget.child,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }
// }

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.grey[900],
      body: DraggableLiquidGlassDemo(),
    ),
  ));
}

class DraggableLiquidGlassDemo extends StatefulWidget {
  @override
  _DraggableLiquidGlassDemoState createState() => _DraggableLiquidGlassDemoState();
}

class _DraggableLiquidGlassDemoState extends State<DraggableLiquidGlassDemo> {
  // Track positions of draggable widgets
  Offset _widget1Position = Offset(100, 100);
  Offset _widget2Position = Offset(300, 200);
  Offset _widget3Position = Offset(150, 350);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background info
        Positioned(
          top: 20,
          left: 20,
          child: Text(
            "🎯 DRAG THE LIQUID GLASS WIDGETS AROUND!",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Draggable Widget 1 - Container
        Positioned(
          left: _widget1Position.dx,
          top: _widget1Position.dy,
          child: DraggableLiquidGlassWrapper(
            intensity: 0.8,
            effectColor: Colors.cyan,
            onPositionChanged: (newPosition) {
              setState(() {
                _widget1Position = newPosition;
              });
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      "Drag Me!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Draggable Widget 2 - Interactive Button
        Positioned(
          left: _widget2Position.dx,
          top: _widget2Position.dy,
          child: DraggableLiquidGlassWrapper(
            intensity: 1.2,
            effectColor: Colors.purple,
            onPositionChanged: (newPosition) {
              setState(() {
                _widget2Position = newPosition;
              });
            },
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("🎉 Draggable button pressed!"),
                    backgroundColor: Colors.purple,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rocket_launch, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Click & Drag!", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),

        // Draggable Widget 3 - Animated Card
        Positioned(
          left: _widget3Position.dx,
          top: _widget3Position.dy,
          child: DraggableLiquidGlassWrapper(
            intensity: 0.6,
            effectColor: Colors.green,
            enableAnimation: true,
            animationSpeed: 2.0,
            onPositionChanged: (newPosition) {
              setState(() {
                _widget3Position = newPosition;
              });
            },
            child: Card(
              color: Colors.orange[300],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      "Animated\nDraggable",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Instructions
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "✨ Each widget has its own liquid glass effect!\n"
              "🎮 Drag them around and watch the effects follow!\n"
              "🔥 The button is still clickable while dragging!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// Enhanced LiquidGlassWrapper with draggable functionality
class DraggableLiquidGlassWrapper extends StatefulWidget {
  final Widget child;
  final double intensity;
  final Color effectColor;
  final bool enableAnimation;
  final double animationSpeed;
  final Function(Offset)? onPositionChanged;

  const DraggableLiquidGlassWrapper({
    Key? key,
    required this.child,
    this.intensity = 1.0,
    this.effectColor = Colors.white,
    this.enableAnimation = true,
    this.animationSpeed = 1.0,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  _DraggableLiquidGlassWrapperState createState() => _DraggableLiquidGlassWrapperState();
}

class _DraggableLiquidGlassWrapperState extends State<DraggableLiquidGlassWrapper>
    with SingleTickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();
  ui.Image? _sdfTexture;
  late AnimationController _controller;
  double _time = 0.0;
  ui.FragmentShader? _shader;
  bool _isInitialized = false;
  Timer? _sdfUpdateTimer;
  Size _childSize = Size(100, 100);
  
  // Dragging state
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (10 / widget.animationSpeed).round()),
    )..addListener(() {
        if (widget.enableAnimation && mounted) {
          setState(() {
            _time = _controller.value * 10.0 * widget.animationSpeed;
          });
        }
      });

    if (widget.enableAnimation) {
      _controller.repeat();
    }

    _initializeShader();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChild();
      _updateSDF();
      // Update SDF periodically for dynamic content
      _sdfUpdateTimer = Timer.periodic(Duration(milliseconds: 300), (_) {
        if (mounted) {
          _measureChild();
          _updateSDF();
        }
      });
    });
  }

  /// Measure the child widget size safely
  void _measureChild() {
    final renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final newSize = renderBox.size;
      if (newSize.width > 0 && newSize.height > 0 && newSize != _childSize) {
        setState(() {
          _childSize = newSize;
        });
      }
    }
  }

  /// Initialize fragment shader
  Future<void> _initializeShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
      _shader = program.fragmentShader();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Shader loading failed: $e");
      if (mounted) {
        setState(() {
          _isInitialized = true; // Use fallback
        });
      }
    }
  }

  /// Capture child widget and generate SDF
  Future<void> _updateSDF() async {
    if (!mounted || _childSize.width <= 0 || _childSize.height <= 0) return;
    
    try {
      final image = await _captureChildImage();
      if (image == null || !mounted) return;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null || !mounted) return;

      final rgbaBytes = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      // Generate SDF using optimized isolate computation
      final sdfBytes = await compute(_generateOptimizedSDF, {
        "pixels": rgbaBytes,
        "width": width,
        "height": height,
        "threshold": 128,
        "maxDistance": 32.0,
      });

      if (!mounted) return;

      // Convert to RGBA texture
      final sdfRGBA = Uint8List(width * height * 4);
      for (int i = 0; i < width * height; i++) {
        final v = sdfBytes[i];
        sdfRGBA[i * 4] = v;     // R
        sdfRGBA[i * 4 + 1] = v; // G  
        sdfRGBA[i * 4 + 2] = v; // B
        sdfRGBA[i * 4 + 3] = 255; // A
      }

      ui.decodeImageFromPixels(
        sdfRGBA,
        width,
        height,
        ui.PixelFormat.rgba8888,
        (img) {
          if (mounted) {
            setState(() {
              _sdfTexture = img;
            });
          }
        },
      );
    } catch (e) {
      debugPrint("Error updating SDF: $e");
    }
  }

  /// Capture child widget as image
  Future<ui.Image?> _captureChildImage() async {
    try {
      final boundary = _childKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) return null;
      
      // Wait for any pending paint operations
      await Future.delayed(Duration(milliseconds: 16));
      
      return await boundary.toImage(pixelRatio: 1.5);
    } catch (e) {
      debugPrint("Error capturing image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
          _dragOffset = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        if (_isDragging && widget.onPositionChanged != null) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final globalPosition = renderBox.localToGlobal(Offset.zero);
          final newPosition = details.globalPosition - _dragOffset - globalPosition;
          widget.onPositionChanged!(newPosition);
        }
      },
      onPanEnd: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      child: AnimatedScale(
        scale: _isDragging ? 1.05 : 1.0,
        duration: Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          decoration: BoxDecoration(
            boxShadow: _isDragging ? [
              BoxShadow(
                color: widget.effectColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ] : null,
          ),
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Original child widget with measurement key
                  RepaintBoundary(
                    key: _childKey,
                    child: widget.child,
                  ),
                  // Liquid glass overlay positioned absolutely
                  if (_isInitialized)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: LiquidGlassPainter(
                            sdfTexture: _sdfTexture,
                            shader: _shader,
                            time: _time,
                            intensity: widget.intensity * (_isDragging ? 1.5 : 1.0), // Boost intensity while dragging
                            effectColor: widget.effectColor,
                            isDragging: _isDragging,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sdfUpdateTimer?.cancel();
    super.dispose();
  }
}

/// Enhanced Custom painter for liquid glass effect with drag feedback
class LiquidGlassPainter extends CustomPainter {
  final ui.Image? sdfTexture;
  final ui.FragmentShader? shader;
  final double time;
  final double intensity;
  final Color effectColor;
  final bool isDragging;

  LiquidGlassPainter({
    required this.sdfTexture,
    required this.shader,
    required this.time,
    required this.intensity,
    required this.effectColor,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (shader != null && sdfTexture != null) {
      // Set shader uniforms with drag enhancement
      shader!.setFloat(0, size.width);   // uResolution.x
      shader!.setFloat(1, size.height);  // uResolution.y
      shader!.setFloat(2, time + (isDragging ? time * 2.0 : 0.0));          // uTime (faster when dragging)
      shader!.setFloat(3, intensity);     // uIntensity
      shader!.setFloat(4, effectColor.red / 255.0);   // uEffectColor.r
      shader!.setFloat(5, effectColor.green / 255.0); // uEffectColor.g
      shader!.setFloat(6, effectColor.blue / 255.0);  // uEffectColor.b
      shader!.setImageSampler(0, sdfTexture!); // uSdfTexture

      final paint = Paint()..shader = shader;
      canvas.drawRect(Offset.zero & size, paint);
    } else {
      // Enhanced fallback effect with drag feedback
      _drawFallbackEffect(canvas, size);
    }
  }

  /// Enhanced fallback when shader unavailable
  void _drawFallbackEffect(Canvas canvas, Size size) {
    final baseOpacity = 0.4 * intensity;
    final dragMultiplier = isDragging ? 1.8 : 1.0;
    
    final paint = Paint()
      ..color = effectColor.withOpacity(baseOpacity * dragMultiplier)
      ..blendMode = BlendMode.overlay;
    
    // Multiple animated layers for richer effect
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width + size.height) / 4;
    
    // Main pulsing circle
    final radius1 = baseRadius * (0.8 + 0.2 * sin(time * (isDragging ? 3.0 : 1.0)));
    canvas.drawCircle(center, radius1, paint);
    
    // Secondary ripple effect when dragging
    if (isDragging) {
      final ripplePaint = Paint()
        ..color = effectColor.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      final rippleRadius = baseRadius * (1.2 + 0.3 * sin(time * 4.0));
      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant LiquidGlassPainter oldDelegate) {
    return oldDelegate.sdfTexture != sdfTexture ||
           oldDelegate.time != time ||
           oldDelegate.intensity != intensity ||
           oldDelegate.effectColor != effectColor ||
           oldDelegate.isDragging != isDragging;
  }
}

/// Optimized SDF generation with SIMD-friendly operations
Uint8List _generateOptimizedSDF(Map<String, dynamic> args) {
  final pixels = args["pixels"] as Uint8List;
  final width = args["width"] as int;
  final height = args["height"] as int;
  final threshold = args["threshold"] as int;
  final maxDistance = args["maxDistance"] as double;

  // Create binary mask from alpha channel
  final mask = Uint8List(width * height);
  for (int i = 0; i < width * height; i++) {
    final alpha = pixels[i * 4 + 3];
    mask[i] = (alpha > threshold) ? 1 : 0;
  }

  // Find boundary pixels using optimized approach
  final boundary = <int>[];
  for (int y = 1; y < height - 1; y++) {
    for (int x = 1; x < width - 1; x++) {
      final idx = y * width + x;
      final current = mask[idx];
      
      // Check 4-connected neighbors for boundary detection
      if (current != mask[idx - 1] ||     // left
          current != mask[idx + 1] ||     // right
          current != mask[idx - width] || // up
          current != mask[idx + width]) { // down
        boundary.add(idx);
      }
    }
  }

  // Compute SDF using optimized distance calculation
  final sdf = Uint8List(width * height);
  
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = y * width + x;
      final isInside = mask[idx] == 1;
      double minDist = maxDistance;
      
      // Find nearest boundary pixel with early termination
      for (final bIdx in boundary) {
        final bx = bIdx % width;
        final by = bIdx ~/ width;
        
        final dx = (x - bx).toDouble();
        final dy = (y - by).toDouble();
        final dist = sqrt(dx * dx + dy * dy);
        
        if (dist < minDist) {
          minDist = dist;
          if (minDist < 1.0) break; // Early termination for close pixels
        }
      }
      
      final signedDist = isInside ? -minDist : minDist;
      final normalized = (signedDist / maxDistance + 1.0) * 0.5; // Map to [0,1]
      sdf[idx] = (normalized.clamp(0.0, 1.0) * 255).toInt();
    }
  }
  
  return sdf;
}
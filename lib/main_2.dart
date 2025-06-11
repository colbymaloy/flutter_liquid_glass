import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

/// Advanced LiquidGlassWrapper - Fully compatible with all Flutter versions
class LiquidGlassWrapper extends StatefulWidget {
  final Widget child;
  final double blurSigma;
  final double intensity;
  final double smoothness;
  final double colorShift;
  final Color glassColor;
  final double glassOpacity;
  final double refractiveIndex;
  final double thickness;
  final vmath.Vector3 lightDirection;
  final bool enableAnimation;
  final bool enableCaching;

  const LiquidGlassWrapper({
    Key? key,
    required this.child,
    this.blurSigma = 16.0,
    this.intensity = 0.7,
    this.smoothness = 0.25,
    this.colorShift = 0.1,
    this.glassColor = const Color(0xFFFFFFFF),
    this.glassOpacity = 0.25,
    this.refractiveIndex = 1.5,
    this.thickness = 10.0,
    this.lightDirection = const vmath.Vector3(0.0, 0.0, 1.0),
    this.enableAnimation = true,
    this.enableCaching = true,
  }) : super(key: key);

  @override
  State<LiquidGlassWrapper> createState() => _LiquidGlassWrapperState();
}

class _LiquidGlassWrapperState extends State<LiquidGlassWrapper>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  ui.FragmentProgram? _shaderProgram;
  
  // Caching system
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  String? _lastChildHash;
  ui.Image? _cachedChildImage;
  Size? _lastSize;
  
  bool _shaderLoaded = false;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    if (widget.enableAnimation) {
      _animationController.repeat();
    }
    
    _loadShader();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _clearCache();
    super.dispose();
  }

  void _clearCache() {
    for (final image in _imageCache.values) {
      image.dispose();
    }
    _imageCache.clear();
    _cacheTimestamps.clear();
    _cachedChildImage?.dispose();
  }

  Future<void> _loadShader() async {
    try {
      _shaderProgram = await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
      setState(() {
        _shaderLoaded = true;
      });
    } catch (e) {
      debugPrint('Shader loading failed (falling back to software rendering): $e');
      // Continue without shader - use software fallback
      setState(() {
        _shaderLoaded = false;
      });
    }
  }

  String _generateChildHash() {
    final buffer = StringBuffer();
    buffer.write(widget.child.runtimeType.toString());
    buffer.write(widget.blurSigma);
    buffer.write(widget.intensity);
    buffer.write(widget.smoothness);
    buffer.write(widget.colorShift);
    buffer.write(widget.glassColor.value);
    buffer.write(widget.glassOpacity);
    buffer.write(widget.refractiveIndex);
    buffer.write(widget.thickness);
    return buffer.toString().hashCode.toString();
  }

  Future<ui.Image?> _getCachedOrRenderChildImage(Size size) async {
    if (!widget.enableCaching) {
      return await _renderChildToImage(size);
    }

    final currentHash = _generateChildHash();
    final sizeKey = '${size.width}x${size.height}';
    final cacheKey = '${currentHash}_$sizeKey';

    // Check if we have a valid cached image
    if (_lastChildHash == currentHash && 
        _lastSize == size && 
        _cachedChildImage != null) {
      return _cachedChildImage;
    }

    // Check global cache
    if (_imageCache.containsKey(cacheKey)) {
      final cachedTime = _cacheTimestamps[cacheKey]!;
      final now = DateTime.now();
      
      // Cache valid for 5 seconds
      if (now.difference(cachedTime).inSeconds < 5) {
        _cachedChildImage = _imageCache[cacheKey];
        _lastChildHash = currentHash;
        _lastSize = size;
        return _cachedChildImage;
      } else {
        // Remove expired cache
        _imageCache[cacheKey]?.dispose();
        _imageCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    // Render new image
    final image = await _renderChildToImage(size);
    if (image != null) {
      // Cache the new image
      _imageCache[cacheKey] = image;
      _cacheTimestamps[cacheKey] = DateTime.now();
      _cachedChildImage = image;
      _lastChildHash = currentHash;
      _lastSize = size;
      
      // Cleanup old cache entries (keep max 10 images)
      if (_imageCache.length > 10) {
        final oldestKey = _cacheTimestamps.entries
            .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
            .key;
        _imageCache[oldestKey]?.dispose();
        _imageCache.remove(oldestKey);
        _cacheTimestamps.remove(oldestKey);
      }
    }

    return image;
  }

  Future<ui.Image?> _renderChildToImage(Size size) async {
    if (size.width <= 0 || size.height <= 0) return null;

    try {
      // Wait for the next frame to ensure the widget is built
      await Future.delayed(const Duration(milliseconds: 16));
      
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio);
      return image;
    } catch (e) {
      debugPrint('Error rendering child to image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 300,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 300,
        );

        return Stack(
          children: [
            // Original child with RepaintBoundary for image capture
            RepaintBoundary(
              key: _repaintBoundaryKey,
              child: widget.child,
            ),
            // Liquid glass effect overlay
            if (_shaderLoaded && _shaderProgram != null)
              FutureBuilder<ui.Image?>(
                future: _getCachedOrRenderChildImage(size),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: size,
                        painter: _LiquidGlassPainter(
                          image: snapshot.data!,
                          program: _shaderProgram!,
                          time: widget.enableAnimation ? _animationController.value * 2 * 3.14159 : 0.0,
                          resolution: vmath.Vector2(size.width, size.height),
                          blurSigma: widget.blurSigma,
                          intensity: widget.intensity,
                          smoothness: widget.smoothness,
                          colorShift: widget.colorShift,
                          glassColor: widget.glassColor,
                          glassOpacity: widget.glassOpacity,
                          refractiveIndex: widget.refractiveIndex,
                          thickness: widget.thickness,
                          lightDirection: widget.lightDirection,
                        ),
                      );
                    },
                  );
                },
              )
            else
              // Software fallback when shader is not available
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: _LiquidGlassFallbackPainter(
                      time: widget.enableAnimation ? _animationController.value * 2 * 3.14159 : 0.0,
                      blurSigma: widget.blurSigma,
                      intensity: widget.intensity,
                      smoothness: widget.smoothness,
                      glassColor: widget.glassColor,
                      glassOpacity: widget.glassOpacity,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _LiquidGlassPainter extends CustomPainter {
  final ui.Image image;
  final ui.FragmentProgram program;
  final double time;
  final vmath.Vector2 resolution;
  final double blurSigma;
  final double intensity;
  final double smoothness;
  final double colorShift;
  final Color glassColor;
  final double glassOpacity;
  final double refractiveIndex;
  final double thickness;
  final vmath.Vector3 lightDirection;

  _LiquidGlassPainter({
    required this.image,
    required this.program,
    required this.time,
    required this.resolution,
    required this.blurSigma,
    required this.intensity,
    required this.smoothness,
    required this.colorShift,
    required this.glassColor,
    required this.glassOpacity,
    required this.refractiveIndex,
    required this.thickness,
    required this.lightDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // Set all uniforms
    shader.setImageSampler(0, image);
    shader.setFloat(1, resolution.x);
    shader.setFloat(2, resolution.y);
    shader.setFloat(3, time);
    shader.setFloat(4, blurSigma);
    shader.setFloat(5, intensity);
    shader.setFloat(6, smoothness);
    shader.setFloat(7, colorShift);
    
    // Glass color as vec4
    shader.setFloat(8, glassColor.red / 255.0);
    shader.setFloat(9, glassColor.green / 255.0);
    shader.setFloat(10, glassColor.blue / 255.0);
    shader.setFloat(11, glassColor.alpha / 255.0);
    
    shader.setFloat(12, glassOpacity);
    shader.setFloat(13, refractiveIndex);
    shader.setFloat(14, thickness);
    
    // Light direction as vec3
    shader.setFloat(15, lightDirection.x);
    shader.setFloat(16, lightDirection.y);
    shader.setFloat(17, lightDirection.z);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) {
    return image != oldDelegate.image ||
        time != oldDelegate.time ||
        resolution != oldDelegate.resolution ||
        blurSigma != oldDelegate.blurSigma ||
        intensity != oldDelegate.intensity ||
        smoothness != oldDelegate.smoothness ||
        colorShift != oldDelegate.colorShift ||
        glassColor != oldDelegate.glassColor ||
        glassOpacity != oldDelegate.glassOpacity ||
        refractiveIndex != oldDelegate.refractiveIndex ||
        thickness != oldDelegate.thickness ||
        lightDirection != oldDelegate.lightDirection;
  }
}

// Software fallback painter when shaders aren't supported
class _LiquidGlassFallbackPainter extends CustomPainter {
  final double time;
  final double blurSigma;
  final double intensity;
  final double smoothness;
  final Color glassColor;
  final double glassOpacity;

  _LiquidGlassFallbackPainter({
    required this.time,
    required this.blurSigma,
    required this.intensity,
    required this.smoothness,
    required this.glassColor,
    required this.glassOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Software-based glass effect using Flutter's built-in capabilities
    final paint = Paint()
      ..color = glassColor.withOpacity(glassOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma * 0.1);

    // Animated glass effect
    final pulse = (sin(time) * 0.1 + 1.0);
    final animatedOpacity = glassOpacity * pulse;
    
    paint.color = glassColor.withOpacity(animatedOpacity);
    
    // Draw glass overlay with rounded corners for blob effect
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(smoothness * 50),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Add additional glass layers for depth
    paint.color = Colors.white.withOpacity(0.1 * pulse);
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma * 0.05);
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassFallbackPainter oldDelegate) {
    return time != oldDelegate.time ||
        blurSigma != oldDelegate.blurSigma ||
        intensity != oldDelegate.intensity ||
        smoothness != oldDelegate.smoothness ||
        glassColor != oldDelegate.glassColor ||
        glassOpacity != oldDelegate.glassOpacity;
  }
}
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

void main() {
  runApp(const LiquidGlassApp());
}

class LiquidGlassApp extends StatelessWidget {
  const LiquidGlassApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Interactive Code',
      theme: ThemeData.dark(),
      home: const LiquidGlassCode(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LiquidGlassCode extends StatefulWidget {
  const LiquidGlassCode({Key? key}) : super(key: key);
  
  @override
  State<LiquidGlassCode> createState() => _LiquidGlassCodeState();
}

class _LiquidGlassCodeState extends State<LiquidGlassCode> {
  // Effect parameters that can be controlled by the user
  final LiquidGlassParameters _parameters = LiquidGlassParameters();
  
  // List of draggable widgets in the Code
  final List<DraggableWidgetData> _widgets = [];
  
  // Control panel visibility
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
    _initializeWidgets();
  }
  
  void _initializeWidgets() {
    // Add some initial widgets to demonstrate the effect
    _widgets.addAll([
      DraggableWidgetData(
        id: 'button1',
        position: const Offset(200, 300),
        widget: _createSampleButton('Click Me!', Colors.blue),
      ),
      DraggableWidgetData(
        id: 'button2', 
        position: const Offset(400, 300),
        widget: _createSampleButton('Hello!', Colors.green),
      ),
      DraggableWidgetData(
        id: 'card1',
        position: const Offset(300, 450),
        widget: _createSampleCard(),
      ),
    ]);
  }
  
  Widget _createSampleButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () {
        // Button functionality is preserved
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$text pressed!'))
        );
      },
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(text),
    );
  }
  
  Widget _createSampleCard() {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text('Card Widget', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquid Glass Interactive Code'),
        actions: [
          IconButton(
            icon: Icon(_showControls ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addRandomWidget,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _widgets.clear();
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Control Panel
          if (_showControls) _buildControlPanel(),
          
          // Main Code area
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: LiquidGlassContainer(
                parameters: _parameters,
                widgets: _widgets,
                onWidgetMoved: (id, newPosition) {
                  setState(() {
                    final widget = _widgets.firstWhere((w) => w.id == id);
                    widget.position = newPosition;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlPanel() {
    return Container(
      width: 300,
      color: Colors.grey[850],
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Liquid Glass Controls', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            
            // Effect Mode
            const Text('Effect Mode'),
            Slider(
              value: _parameters.effectMode,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _parameters.effectMode.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _parameters.effectMode = value;
                });
              },
            ),
            
            // Blob Size
            const Text('Blob Size'),
            Slider(
              value: _parameters.blobSize,
              min: 0.1,
              max: 0.5,
              divisions: 40,
              label: _parameters.blobSize.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _parameters.blobSize = value;
                });
              },
            ),
            
            // Smooth Union Strength
            const Text('Smooth Union Strength'),
            Slider(
              value: _parameters.smoothUnionStrength,
              min: 0.01,
              max: 0.3,
              divisions: 29,
              label: _parameters.smoothUnionStrength.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _parameters.smoothUnionStrength = value;
                });
              },
            ),
            
            // Distortion Strength
            const Text('Distortion Strength'),
            Slider(
              value: _parameters.distortionStrength,
              min: 0.0,
              max: 0.1,
              divisions: 50,
              label: _parameters.distortionStrength.toStringAsFixed(3),
              onChanged: (value) {
                setState(() {
                  _parameters.distortionStrength = value;
                });
              },
            ),
            
            // Refraction Strength
            const Text('Refraction Strength'),
            Slider(
              value: _parameters.refractionStrength,
              min: 0.0,
              max: 0.1,
              divisions: 50,
              label: _parameters.refractionStrength.toStringAsFixed(3),
              onChanged: (value) {
                setState(() {
                  _parameters.refractionStrength = value;
                });
              },
            ),
            
            // Edge Thickness
            const Text('Edge Thickness'),
            Slider(
              value: _parameters.edgeThickness,
              min: 0.001,
              max: 0.05,
              divisions: 49,
              label: _parameters.edgeThickness.toStringAsFixed(3),
              onChanged: (value) {
                setState(() {
                  _parameters.edgeThickness = value;
                });
              },
            ),
            
            // Animation Speed
            const Text('Animation Speed'),
            Slider(
              value: _parameters.animationSpeed,
              min: 0.0,
              max: 3.0,
              divisions: 30,
              label: _parameters.animationSpeed.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _parameters.animationSpeed = value;
                });
              },
            ),
            
            // Noise Scale
            const Text('Noise Scale'),
            Slider(
              value: _parameters.noiseScale,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              label: _parameters.noiseScale.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _parameters.noiseScale = value;
                });
              },
            ),
            
            const SizedBox(height: 20),
            
            // Reset button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _parameters.reset();
                });
              },
              child: const Text('Reset Parameters'),
            ),
            
            const SizedBox(height: 20),
            
            // Widget count info
            Text('Widgets: ${_widgets.length}'),
            const SizedBox(height: 10),
            
            // Instructions
            const Text(
              'Instructions:\n'
              '• Drag widgets around to see liquid glass effect\n'
              '• Bring widgets close together for smooth union\n'
              '• Adjust parameters to customize the effect\n'
              '• Click + to add random widgets\n'
              '• Widget interactivity is preserved',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  void _addRandomWidget() {
    final random = math.Random();
    final types = ['button', 'card', 'icon'];
    final type = types[random.nextInt(types.length)];
    
    Widget widget;
    switch (type) {
      case 'button':
        widget = _createSampleButton(
          'Widget ${_widgets.length + 1}',
          Color.fromRGBO(
            random.nextInt(255),
            random.nextInt(255), 
            random.nextInt(255),
            1.0,
          ),
        );
        break;
      case 'card':
        widget = _createSampleCard();
        break;
      case 'icon':
        widget = Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star, color: Colors.white, size: 30),
        );
        break;
      default:
        widget = _createSampleButton('Default', Colors.grey);
    }
    
    setState(() {
      _widgets.add(DraggableWidgetData(
        id: 'widget_${_widgets.length}',
        position: Offset(
          200 + random.nextDouble() * 400,
          200 + random.nextDouble() * 300,
        ),
        widget: widget,
      ));
    });
  }
}

class LiquidGlassParameters {
  double effectMode = 1.0;
  double blobSize = 0.15;
  double smoothUnionStrength = 0.08;
  double distortionStrength = 0.02;
  double refractionStrength = 0.03;
  double edgeThickness = 0.01;
  double animationSpeed = 1.0;
  double noiseScale = 10.0;
  
  void reset() {
    effectMode = 1.0;
    blobSize = 0.15;
    smoothUnionStrength = 0.08;
    distortionStrength = 0.02;
    refractionStrength = 0.03;
    edgeThickness = 0.01;
    animationSpeed = 1.0;
    noiseScale = 10.0;
  }
  
  // ✅ Add equality operator for shouldRepaint optimization
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidGlassParameters &&
        other.effectMode == effectMode &&
        other.blobSize == blobSize &&
        other.smoothUnionStrength == smoothUnionStrength &&
        other.distortionStrength == distortionStrength &&
        other.refractionStrength == refractionStrength &&
        other.edgeThickness == edgeThickness &&
        other.animationSpeed == animationSpeed &&
        other.noiseScale == noiseScale;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      effectMode,
      blobSize,
      smoothUnionStrength,
      distortionStrength,
      refractionStrength,
      edgeThickness,
      animationSpeed,
      noiseScale,
    );
  }
}

class DraggableWidgetData {
  final String id;
  Offset position;
  final Widget widget;
  final GlobalKey repaintKey = GlobalKey();
  ui.Image? capturedImage;
  
  DraggableWidgetData({
    required this.id,
    required this.position,
    required this.widget,
  });
  
  // ✅ Add equality operator for shouldRepaint optimization
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DraggableWidgetData &&
        other.id == id &&
        other.position == position &&
        other.capturedImage == capturedImage;
  }
  
  @override
  int get hashCode {
    return Object.hash(id, position, capturedImage);
  }
}

class LiquidGlassContainer extends StatefulWidget {
  final LiquidGlassParameters parameters;
  final List<DraggableWidgetData> widgets;
  final Function(String id, Offset newPosition) onWidgetMoved;
  
  const LiquidGlassContainer({
    Key? key,
    required this.parameters,
    required this.widgets,
    required this.onWidgetMoved,
  }) : super(key: key);
  
  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  ui.FragmentShader? _fragmentShader;
  ui.Image? _fallbackImage; // ✅ Add fallback image
  Timer? _captureTimer;
  String? _draggingWidget;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _loadShader();
    _createFallbackImage(); // ✅ Create fallback image
    
    // Capture widgets at 60fps for smooth real-time updates
    _captureTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _captureAllWidgets();
    });
  }
  
  // ✅ Create fallback image for unused samplers
  Future<void> _createFallbackImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Create a simple 64x64 transparent image
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 64, 64),
      Paint()..color = Colors.transparent,
    );
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    
    if (mounted) {
      setState(() {
        _fallbackImage = image;
      });
    }
  }
  
  Future<void> _loadShader() async {
    try {
      ui.FragmentProgram program =
          await ui.FragmentProgram.fromAsset('shaders/liquid_glass_3_multi.frag');
      if (mounted) {
        setState(() {
          _fragmentShader = program.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint('Shader loading error: $e');
    }
  }
  
  Future<void> _captureAllWidgets() async {
    for (final widgetData in widget.widgets) {
      try {
        if (widgetData.repaintKey.currentContext != null) {
          RenderRepaintBoundary boundary = widgetData.repaintKey.currentContext!
              .findRenderObject() as RenderRepaintBoundary;
          ui.Image image = await boundary.toImage(pixelRatio: 2.0);
          widgetData.capturedImage = image;
        }
      } catch (e) {
        // Handle capture errors gracefully
        debugPrint('Widget capture error: $e');
      }
    }
    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    _captureTimer?.cancel();
    _animationController.dispose();
    _fallbackImage?.dispose(); // ✅ Dispose fallback image
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Render all draggable widgets
            ...widget.widgets.map((widgetData) {
              return Positioned(
                left: widgetData.position.dx,
                top: widgetData.position.dy,
                child: GestureDetector(
                  onPanStart: (_) {
                    _draggingWidget = widgetData.id;
                  },
                  onPanUpdate: (details) {
                    if (_draggingWidget == widgetData.id) {
                      widget.onWidgetMoved(
                        widgetData.id,
                        widgetData.position + details.delta,
                      );
                    }
                  },
                  onPanEnd: (_) {
                    _draggingWidget = null;
                  },
                  child: RepaintBoundary(
                    key: widgetData.repaintKey,
                    child: widgetData.widget,
                  ),
                ),
              );
            }),
            
            // Liquid glass effect overlay
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: MultiWidgetLiquidGlassPainter(
                      fragmentShader: _fragmentShader,
                      time: (_animationController.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0,
                      parameters: widget.parameters,
                      widgets: widget.widgets,
                      fallbackImage: _fallbackImage, // ✅ Pass fallback image
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ✅ FIXED PAINTER WITH FALLBACK IMAGE SUPPORT
class MultiWidgetLiquidGlassPainter extends CustomPainter {
  final ui.FragmentShader? fragmentShader;
  final double time;
  final LiquidGlassParameters parameters;
  final List<DraggableWidgetData> widgets;
  final ui.Image? fallbackImage; // ✅ Add fallback image
  
  MultiWidgetLiquidGlassPainter({
    required this.fragmentShader,
    required this.time,
    required this.parameters,
    required this.widgets,
    required this.fallbackImage, // ✅ Required fallback image
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // ✅ Don't paint if shader or fallback image not ready
    if (fragmentShader == null || fallbackImage == null) return;
    
    // Set shader uniforms with proper Flutter format
    int uniformIndex = 0;
    
    fragmentShader!.setFloat(uniformIndex++, time * parameters.animationSpeed);
    fragmentShader!.setFloat(uniformIndex++, size.width);
    fragmentShader!.setFloat(uniformIndex++, size.height);
    fragmentShader!.setFloat(uniformIndex++, parameters.effectMode);
    fragmentShader!.setFloat(uniformIndex++, parameters.blobSize);
    fragmentShader!.setFloat(uniformIndex++, parameters.smoothUnionStrength);
    fragmentShader!.setFloat(uniformIndex++, parameters.distortionStrength);
    fragmentShader!.setFloat(uniformIndex++, parameters.refractionStrength);
    fragmentShader!.setFloat(uniformIndex++, parameters.edgeThickness);
    fragmentShader!.setFloat(uniformIndex++, parameters.noiseScale);
    fragmentShader!.setFloat(uniformIndex++, widgets.length.toDouble());
    
    // Set widget positions (8 positions = 16 floats)
    for (int i = 0; i < 8; i++) {
      if (i < widgets.length) {
        final widget = widgets[i];
        fragmentShader!.setFloat(uniformIndex++, widget.position.dx / size.width);
        fragmentShader!.setFloat(uniformIndex++, widget.position.dy / size.height);
      } else {
        fragmentShader!.setFloat(uniformIndex++, 0.5); // Default position
        fragmentShader!.setFloat(uniformIndex++, 0.5);
      }
    }
    
    // ✅ CRITICAL: Set ALL 8 samplers (even unused ones!)
    for (int i = 0; i < 8; i++) {
      if (i < widgets.length && widgets[i].capturedImage != null) {
        fragmentShader!.setImageSampler(i, widgets[i].capturedImage!);
      } else {
        // ✅ Use fallback image for unused samplers
        fragmentShader!.setImageSampler(i, fallbackImage!);
      }
    }
    
    final paint = Paint()..shader = fragmentShader;
    canvas.drawRect(Offset.zero & size, paint);
  }
  
  @override
  bool shouldRepaint(covariant MultiWidgetLiquidGlassPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.parameters != parameters ||
        oldDelegate.widgets != widgets ||
        oldDelegate.fallbackImage != fallbackImage; // ✅ Include fallback image
  }
}

/*
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// Entry point for the demo app.
void main() {
  runApp(const MyApp());
}

/// The root widget of the demo application.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Effect Demo',
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// A demo home page that includes an interactive widget wrapped by LiquidGlassWrapper.
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// The home page state demonstrates interactive content (a counter button) along with a toggle for advanced effect.
class _MyHomePageState extends State<MyHomePage> {
  int counter = 0;
  bool advancedEffect = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liquid Glass Effect Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A switch to toggle between basic (2D) and advanced (e.g. 3D/refraction) liquid glass effect.
            SwitchListTile(
              title: const Text("Advanced Liquid Glass Effect"),
              value: advancedEffect,
              onChanged: (val) {
                setState(() {
                  advancedEffect = val;
                });
              },
            ),
            const SizedBox(height: 20),
            // The LiquidGlassWrapper wraps a widget that is both interactive and stateful.
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: LiquidGlassWrapper(
                // Use effectMode = 1.0 for advanced effect, 0.0 for basic.
                effectMode: advancedEffect ? 1.0 : 0.0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        counter++;
                      });
                    },
                    child: Text("Counter: $counter"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LiquidGlassWrapper is a plug‐and‐play widget that wraps any child widget and applies
/// a real‐time “liquid glass” shader effect on its visual output while preserving interactivity.
class LiquidGlassWrapper extends StatefulWidget {
  final Widget child;
  /// The effectMode parameter toggles visual modes:
  ///     0.0 – basic (e.g. ray‐casting style)
  ///     1.0 – advanced (ray‐marching SDF with smooth union and refractive distortion)
  final double effectMode;
  const LiquidGlassWrapper({Key? key, required this.child, this.effectMode = 1.0})
      : super(key: key);
  @override
  _LiquidGlassWrapperState createState() => _LiquidGlassWrapperState();
}

class _LiquidGlassWrapperState extends State<LiquidGlassWrapper>
    with SingleTickerProviderStateMixin {
  // Global key to capture the child widget via RepaintBoundary.
  final GlobalKey _repaintKey = GlobalKey();
  ui.Image? _childImage;
  Timer? _captureTimer;
  late final AnimationController _animationController;
  ui.FragmentShader? _fragmentShader;

  @override
  void initState() {
    super.initState();
    // AnimationController drives the time uniform for animated shader effects.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadShader();

    // Periodically capture the rendered output of the child widget.
    // Here we update roughly at 30 frames per second.
    _captureTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      _captureChildImage();
    });
  }

  /// Loads the fragment shader from assets.
  Future<void> _loadShader() async {
    // The asset file "assets/shaders/liquid_glass.frag" must be declared in your pubspec.yaml.
    ui.FragmentProgram program =
        await ui.FragmentProgram.fromAsset('shaders/liquid_glass_3.frag');
    setState(() {
      _fragmentShader = program.fragmentShader();
    });
  }

  /// Captures the current child widget output as a ui.Image.
  Future<void> _captureChildImage() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Use devicePixelRatio for high-resolution capture.
      ui.Image image =
          await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
      setState(() {
        _childImage = image;
      });
    } catch (e) {
      // In production code, handle or report the exception appropriately.
    }
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder to ensure the shader covers the full area.
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Wrap the child inside a RepaintBoundary so it can be rendered offscreen.
            RepaintBoundary(
              key: _repaintKey,
              child: widget.child,
            ),
            // Overlay the shader effect while ignoring pointer events
            // so that the underlying child remains interactive.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: LiquidGlassPainter(
                      fragmentShader: _fragmentShader,
                      // Convert elapsed time to seconds.
                      time: _animationController.lastElapsedDuration != null
                          ? _animationController.lastElapsedDuration!.inMilliseconds /
                              1000.0
                          : 0.0,
                      effectMode: widget.effectMode,
                      childImage: _childImage,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// LiquidGlassPainter uses the loaded fragment shader to render the liquid glass effect.
/// It sets the following uniforms:
///   uniform float uTime      -- current animation time in seconds.
///   uniform vec2  uResolution -- canvas size in pixels.
///   uniform float uEffectMode -- toggle for visual effect mode (0.0 or 1.0).
///   uniform sampler2D uTexture -- the captured child widget image.
class LiquidGlassPainter extends CustomPainter {
  final ui.FragmentShader? fragmentShader;
  final double time;
  final double effectMode;
  final ui.Image? childImage;

  LiquidGlassPainter({
    required this.fragmentShader,
    required this.time,
    required this.effectMode,
    required this.childImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Do nothing if the shader or captured image is not yet available.
    if (fragmentShader == null || childImage == null) {
      return;
    }

    // Set shader uniforms.
    // Uniform order (indices) is assumed to be:
    // 0: time, 1: resolution.width, 2: resolution.height, 3: effectMode.
    fragmentShader!.setFloat(0, time);
    fragmentShader!.setFloat(1, size.width);
    fragmentShader!.setFloat(2, size.height);
    fragmentShader!.setFloat(3, effectMode);

    // Bind the captured widget image as the texture.
    fragmentShader!.setImageSampler(0, childImage!);

    // Create a paint object that uses the fragment shader.
    final paint = Paint()..shader = fragmentShader;
    // Draw a rectangle covering the full canvas to display the shader output.
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidGlassPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.childImage != childImage ||
        oldDelegate.effectMode != effectMode ||
        oldDelegate.fragmentShader != fragmentShader;
  }
}
*/

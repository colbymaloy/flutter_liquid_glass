import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

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
  final LiquidGlassParameters _parameters = LiquidGlassParameters();
  final List<DraggableWidgetData> _widgets = [];
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
    _initializeWidgets();
  }
  
  void _initializeWidgets() {
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
          if (_showControls) _buildControlPanel(),
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
            
            _buildSlider('Effect Mode', _parameters.effectMode, 0.0, 2.0, (v) {
              setState(() => _parameters.effectMode = v);
            }),
            
            _buildSlider('Blob Size', _parameters.blobSize, 0.05, 0.3, (v) {
              setState(() => _parameters.blobSize = v);
            }),
            
            _buildSlider('Smooth Union', _parameters.smoothUnionStrength, 0.01, 0.2, (v) {
              setState(() => _parameters.smoothUnionStrength = v);
            }),
            
            _buildSlider('Distortion', _parameters.distortionStrength, 0.0, 0.05, (v) {
              setState(() => _parameters.distortionStrength = v);
            }),
            
            _buildSlider('Refraction', _parameters.refractionStrength, 0.0, 0.05, (v) {
              setState(() => _parameters.refractionStrength = v);
            }),
            
            _buildSlider('Edge Thickness', _parameters.edgeThickness, 0.001, 0.03, (v) {
              setState(() => _parameters.edgeThickness = v);
            }),
            
            _buildSlider('Animation Speed', _parameters.animationSpeed, 0.0, 3.0, (v) {
              setState(() => _parameters.animationSpeed = v);
            }),
            
            _buildSlider('Noise Scale', _parameters.noiseScale, 1.0, 20.0, (v) {
              setState(() => _parameters.noiseScale = v);
            }),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _parameters.reset();
                });
              },
              child: const Text('Reset Parameters'),
            ),
            
            const SizedBox(height: 20),
            Text('Widgets: ${_widgets.length}'),
            const SizedBox(height: 10),
            
            const Text(
              'Instructions:\n'
              '• Drag widgets around\n'
              '• Bring widgets close for smooth union\n'
              '• Adjust parameters to customize\n'
              '• Click + to add widgets\n'
              '• Widget interactivity preserved',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 50,
          label: value.toStringAsFixed(3),
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
      ],
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
  double blobSize = 0.1;
  double smoothUnionStrength = 0.05;
  double distortionStrength = 0.02;
  double refractionStrength = 0.01;
  double edgeThickness = 0.01;
  double animationSpeed = 1.0;
  double noiseScale = 10.0;
  
  void reset() {
    effectMode = 1.0;
    blobSize = 0.1;
    smoothUnionStrength = 0.05;
    distortionStrength = 0.02;
    refractionStrength = 0.01;
    edgeThickness = 0.01;
    animationSpeed = 1.0;
    noiseScale = 10.0;
  }
}

class DraggableWidgetData {
  final String id;
  Offset position;
  final Widget widget;
  
  DraggableWidgetData({
    required this.id,
    required this.position,
    required this.widget,
  });
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
  String? _draggingWidget;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _loadShader();
  }
  
  Future<void> _loadShader() async {
    try {
      ui.FragmentProgram program =
          await ui.FragmentProgram.fromAsset('shaders/liquid_glass_3_multi.frag');
      setState(() {
        _fragmentShader = program.fragmentShader();
      });
    } catch (e) {
      debugPrint('Shader loading error: $e');
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Liquid glass effect background
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: SimplifiedLiquidGlassPainter(
                    fragmentShader: _fragmentShader,
                    time: (_animationController.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0,
                    parameters: widget.parameters,
                    widgets: widget.widgets,
                  ),
                );
              },
            ),
            
            // Render all draggable widgets on top
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
                  child: widgetData.widget,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class SimplifiedLiquidGlassPainter extends CustomPainter {
  final ui.FragmentShader? fragmentShader;
  final double time;
  final LiquidGlassParameters parameters;
  final List<DraggableWidgetData> widgets;
  
  SimplifiedLiquidGlassPainter({
    required this.fragmentShader,
    required this.time,
    required this.parameters,
    required this.widgets,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (fragmentShader == null) return;
    
    // Set shader uniforms - NO TEXTURE SAMPLERS!
    fragmentShader!.setFloat(0, time * parameters.animationSpeed);
    fragmentShader!.setFloat(1, size.width);
    fragmentShader!.setFloat(2, size.height);
    fragmentShader!.setFloat(3, parameters.effectMode);
    fragmentShader!.setFloat(4, parameters.blobSize);
    fragmentShader!.setFloat(5, parameters.smoothUnionStrength);
    fragmentShader!.setFloat(6, parameters.distortionStrength);
    fragmentShader!.setFloat(7, parameters.refractionStrength);
    fragmentShader!.setFloat(8, parameters.edgeThickness);
    fragmentShader!.setFloat(9, parameters.noiseScale);
    fragmentShader!.setFloat(10, widgets.length.toDouble());
    
    // Set widget positions (up to 8 widgets supported)
    for (int i = 0; i < math.min(widgets.length, 8); i++) {
      final widget = widgets[i];
      fragmentShader!.setFloat(11 + i * 2, widget.position.dx / size.width);
      fragmentShader!.setFloat(12 + i * 2, widget.position.dy / size.height);
    }
    
    final paint = Paint()..shader = fragmentShader;
    canvas.drawRect(Offset.zero & size, paint);
  }
  
  @override
  bool shouldRepaint(covariant SimplifiedLiquidGlassPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.parameters != parameters ||
        oldDelegate.widgets != widgets;
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

// main.dart
//
// THE MOST PERFORMAT REAL TIME TOGGLABLE 2D TO 3D & RIGID BODY TO SOFT BODY DYNAMICS
// PHYSICS SIMULATION SANDBOX ENVIORNMENT PURELY MADE IN/USING/UTILIZING/LEVERAGING
// FLUTTER GAME DEV & SCIENTIFIC & LOW LEVEL SOTA OPTIMIZED ECOSYSTEM.
//
// Author: Gemini 2.5 Pro 0605 (with Abacus.AI)
// Date: 2025-06-11
// Revision: 7 (Final - Interactive Drag & Throw Physics)

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

const int kMaxBlobs = 10;

class _LiquidWidgetEntity {
  final GlobalKey key = GlobalKey();
  final Widget child;
  ui.Image? image;
  vm.Vector2 position;
  vm.Vector2 velocity;
  Size size = Size.zero;

  _LiquidWidgetEntity({
    required this.child,
    required this.position,
  }) : velocity = vm.Vector2.zero();
}

class LiquidGlassWrapper extends StatefulWidget {
  final List<Widget> children;
  final bool isSoftBody;
  final bool is3DLook;
  final double viscosity;
  final vm.Vector2 gravity;

  LiquidGlassWrapper({
    super.key,
    required this.children,
    this.isSoftBody = true,
    this.is3DLook = true,
    this.viscosity = 0.2,
    vm.Vector2? gravity,
  }) : gravity = gravity ?? vm.Vector2(0, 200);

  @override
  State<LiquidGlassWrapper> createState() => _LiquidGlassWrapperState();
}

class _LiquidGlassWrapperState extends State<LiquidGlassWrapper>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _shaderProgram;
  late final AnimationController _controller;
  final List<_LiquidWidgetEntity> _entities = [];
  Size _containerSize = Size.zero;

  // *** NEW: State for tracking the dragged entity ***
  _LiquidWidgetEntity? _draggedEntity;

  @override
  void initState() {
    super.initState();
    _loadShader();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(_updateLoop);

    for (var child in widget.children) {
      _entities.add(_LiquidWidgetEntity(
        child: child,
        position: vm.Vector2.zero(),
      ));
    }

    WidgetsBinding.instance.addPostFrameCallback(_onAfterBuild);
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
          'assets/shaders/liquid_glass.frag');
      setState(() {
        _shaderProgram = program;
      });
    } catch (e) {
      debugPrint("FATAL: Error loading shader: $e");
    }
  }

  void _onAfterBuild(Duration timeStamp) {
    if (!mounted) return;
    _captureWidgetImages();
  }

  void _captureWidgetImages() {
    final RenderBox? containerBox = context.findRenderObject() as RenderBox?;
    if (containerBox != null) {
      _containerSize = containerBox.size;
    }

    for (var entity in _entities) {
      final RenderRepaintBoundary? boundary =
          entity.key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null && boundary.size != Size.zero) {
        if (entity.size == Size.zero) {
          entity.size = boundary.size;
        }
        final offset = boundary.localToGlobal(Offset.zero);

        if (entity.position == vm.Vector2.zero()) {
          entity.position.setValues(offset.dx + entity.size.width / 2,
              offset.dy + entity.size.height / 2);
        }

        boundary.toImage(pixelRatio: 1.0).then((image) {
          if (mounted) {
            if (entity.image?.width != image.width ||
                entity.image?.height != image.height) {
              setState(() {
                entity.image = image;
              });
            }
          }
        }).catchError((e) {
          debugPrint("Error capturing widget image: $e");
        });
      }
    }
  }

  void _updateLoop() {
    if (_containerSize == Size.zero || !widget.isSoftBody) return;
    final double dt = 1.0 / 60.0;
    for (var entity in _entities) {
      // *** NEW: If this entity is being dragged, skip physics for it ***
      if (entity == _draggedEntity) {
        continue;
      }

      entity.velocity += widget.gravity * dt;
      entity.position += entity.velocity * dt;
      final halfW = entity.size.width / 2;
      final halfH = entity.size.height / 2;
      if (entity.position.x < halfW) {
        entity.position.x = halfW;
        entity.velocity.x *= -0.6;
      }
      if (entity.position.x > _containerSize.width - halfW) {
        entity.position.x = _containerSize.width - halfW;
        entity.velocity.x *= -0.6;
      }
      if (entity.position.y < halfH) {
        entity.position.y = halfH;
        entity.velocity.y *= -0.6;
      }
      if (entity.position.y > _containerSize.height - halfH) {
        entity.position.y = _containerSize.height - halfH;
        entity.velocity.y *= -0.6;
      }
    }
    setState(() {});
  }

// In class _LiquidGlassWrapperState

@override
Widget build(BuildContext context) {
  if (_shaderProgram == null) {
    return const Center(child: CircularProgressIndicator());
  }
  return Stack(
    fit: StackFit.expand,
    children: [
      // ... (Layer 1: CustomPaint is unchanged)
      CustomPaint(
        painter: _LiquidPainter(
          shaderProgram: _shaderProgram!,
          entities: _entities,
          isSoftBody: widget.isSoftBody,
          is3DLook: widget.is3DLook,
          viscosity: widget.viscosity,
        ),
      ),
      // Layer 2: The original widgets (for capturing images)
      Stack(
        children: _entities.map((entity) {
          final child = RepaintBoundary(
            key: entity.key,
            child: Opacity(
              opacity: widget.isSoftBody ? 0.0 : 1.0,
              // *** THE DEFINITIVE FIX IS HERE ***
              // Wrap the widget in a transparent container to ensure
              // its alpha channel is captured correctly.
              child: Container(
                color: Colors.transparent,
                child: entity.child,
              ),
            ),
          );
          if (widget.isSoftBody) {
            return child;
          } else {
            return Positioned(
              left: entity.position.x - entity.size.width / 2,
              top: entity.position.y - entity.size.height / 2,
              width: entity.size.width,
              height: entity.size.height,
              child: child,
            );
          }
        }).toList(),
      ),
      // ... (Layer 3: Gesture handling is unchanged)
      if (widget.isSoftBody)
        Stack(
          children: _entities.map((entity) {
            if (entity.size == Size.zero) return const SizedBox.shrink();
            return Positioned(
              left: entity.position.x - entity.size.width / 2,
              top: entity.position.y - entity.size.height / 2,
              width: entity.size.width,
              height: entity.size.height,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _draggedEntity = entity;
                    _draggedEntity!.velocity = vm.Vector2.zero();
                  });
                },
                onPanUpdate: (details) {
                  if (_draggedEntity != null) {
                    setState(() {
                      _draggedEntity!.position +=
                          vm.Vector2(details.delta.dx, details.delta.dy);
                    });
                  }
                },
                onPanEnd: (details) {
                  if (_draggedEntity != null) {
                    setState(() {
                      _draggedEntity!.velocity = vm.Vector2(
                        details.velocity.pixelsPerSecond.dx,
                        details.velocity.pixelsPerSecond.dy,
                      );
                      _draggedEntity = null;
                    });
                  }
                },
                child: Container(color: Colors.transparent),
              ),
            );
          }).toList(),
        ),
    ],
  );
}
}

class _LiquidPainter extends CustomPainter {
  final ui.FragmentProgram shaderProgram;
  final List<_LiquidWidgetEntity> entities;
  final bool isSoftBody;
  final bool is3DLook;
  final double viscosity;

  _LiquidPainter({
    required this.shaderProgram,
    required this.entities,
    required this.isSoftBody,
    required this.is3DLook,
    required this.viscosity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final validEntities =
        entities.where((e) => e.image != null && e.size != Size.zero).toList();
    if (validEntities.isEmpty) return;

    final shader = shaderProgram.fragmentShader();

    shader.setFloat(0, viscosity);
    shader.setFloat(1, isSoftBody ? 1.0 : 0.0);
    shader.setFloat(2, is3DLook ? 1.0 : 0.0);

    for (int i = 0; i < kMaxBlobs; i++) {
      final baseIndex = 3 + (i * 4);
      if (i < validEntities.length) {
        final entity = validEntities[i];
        shader.setFloat(baseIndex + 0, entity.position.x);
        shader.setFloat(baseIndex + 1, entity.position.y);
        shader.setFloat(baseIndex + 2, entity.size.width);
        shader.setFloat(baseIndex + 3, entity.size.height);
      } else {
        shader.setFloat(baseIndex + 0, 0);
        shader.setFloat(baseIndex + 1, 0);
        shader.setFloat(baseIndex + 2, 0);
        shader.setFloat(baseIndex + 3, 0);
      }
    }

    for (int i = 0; i < kMaxBlobs; i++) {
      if (i < validEntities.length) {
        shader.setImageSampler(i, validEntities[i].image!);
      } else {
        shader.setImageSampler(i, validEntities.first.image!);
      }
    }

    final paint = Paint()..shader = shader;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

//==============================================================================
// EXAMPLE APP (No changes)
//==============================================================================
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Liquid Glass Demo',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF101015),
        colorScheme: const ColorScheme.dark(
          primary: Colors.lightBlueAccent,
          secondary: Colors.pinkAccent,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LiquidDemoScreen(),
    );
  }
}

class LiquidDemoScreen extends StatefulWidget {
  const LiquidDemoScreen({super.key});
  @override
  State<LiquidDemoScreen> createState() => _LiquidDemoScreenState();
}

class _LiquidDemoScreenState extends State<LiquidDemoScreen> {
  bool _isSoftBody = true;
  bool _is3DLook = true;
  double _viscosity = 0.2;
  double _gravity = 200.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquid Glass Widget Wrapper'),
        backgroundColor: const Color(0x42000000),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              clipBehavior: Clip.antiAlias,
              child: LiquidGlassWrapper(
                isSoftBody: _isSoftBody,
                is3DLook: _is3DLook,
                viscosity: _viscosity,
                gravity: vm.Vector2(0, _gravity),
                children: [
                  const FlutterLogo(size: 80),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Button pressed! Interactivity works!"),
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: const Text("Interactive!"),
                  ),
                  const Icon(Icons.favorite, color: Colors.pink, size: 70),
                  const Text("Any Widget", style: TextStyle(fontSize: 24)),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.deepPurple],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Material(
      color: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Soft Body"),
                    Switch(
                      value: _isSoftBody,
                      onChanged: (val) => setState(() => _isSoftBody = val),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("2.5D Look"),
                    Switch(
                      value: _is3DLook,
                      onChanged: (val) => setState(() => _is3DLook = val),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text("Viscosity (Edge Sharpness): ${_viscosity.toStringAsFixed(2)}"),
            Slider(
              value: _viscosity,
              min: 0.05,
              max: 1.0,
              onChanged: (val) => setState(() => _viscosity = val),
            ),
            Text("Gravity: ${_gravity.toStringAsFixed(0)}"),
            Slider(
              value: _gravity,
              min: -500,
              max: 1000,
              onChanged: (val) => setState(() => _gravity = val),
            ),
          ],
        ),
      ),
    );
  }
}

/*
	// File: main.dart
	import 'dart:async';
	import 'dart:math';
	import 'dart:typed_data'; // Required for Float32List
	import 'dart:ui' as ui;
	import 'package:flutter/foundation.dart'; // Required for listEquals
	import 'package:flutter/material.dart';
	import 'package:flutter/scheduler.dart'; // Required for Ticker
	import 'package:vector_math/vector_math_64.dart' as vm;

	void main() async {
	  WidgetsFlutterBinding.ensureInitialized();

	  // Pre-compile the shader at startup.
	  final program = await ui.FragmentProgram.fromAsset('assets/shaders/metaball_shader.frag');

	  runApp(MyApp(shader: program.fragmentShader()));
	}

	class MyApp extends StatelessWidget {
	  final ui.FragmentShader shader;

	  const MyApp({Key? key, required this.shader}) : super(key: key);

	  @override
	  Widget build(BuildContext context) {
		return MaterialApp(
		  title: 'Flutter Metaball Widgets Demo',
		  debugShowCheckedModeBanner: false,
		  theme: ThemeData.dark().copyWith(
			scaffoldBackgroundColor: const Color(0xFF121212),
		  ),
		  home: MetaballDemo(shader: shader),
		);
	  }
	}

	/// A controller to manage which widgets are part of the metaball effect.
	class MetaballController extends ChangeNotifier {
	  final List<GlobalKey> _keys = [];

	  List<GlobalKey> get keys => _keys;

	  void addKey(GlobalKey key) {
		if (!_keys.contains(key)) {
		  _keys.add(key);
		  // Using a post-frame callback to notify listeners after the widget is in the tree.
		  WidgetsBinding.instance.addPostFrameCallback((_) {
			notifyListeners();
		  });
		}
	  }

	  void removeKey(GlobalKey key) {
		if (_keys.contains(key)) {
		  _keys.remove(key);
		  notifyListeners();
		}
	  }
	}

	/// The main widget that applies the metaball shader effect.
	class MetaballContainer extends StatefulWidget {
	  final ui.FragmentShader shader;
	  final MetaballController controller;
	  final Widget child;
	  final Color color;

	  const MetaballContainer({
		Key? key,
		required this.shader,
		required this.controller,
		required this.child,
		this.color = Colors.lightBlueAccent,
	  }) : super(key: key);

	  @override
	  _MetaballContainerState createState() => _MetaballContainerState();
	}

	class _MetaballContainerState extends State<MetaballContainer> with SingleTickerProviderStateMixin {
	  late final Ticker _ticker;
	  double _time = 0.0;
	  final List<vm.Vector4> _widgetData = [];

	  @override
	  void initState() {
		super.initState();
		widget.controller.addListener(_updateWidgetData);
		_ticker = createTicker((elapsed) {
		  // A continuously running ticker is the simplest way to trigger repaints
		  // for the shader's time uniform, creating potential for time-based animation.
		  setState(() {
			_time += elapsed.inMilliseconds / 1000.0;
		  });
		});
		_ticker.start();

		// Initial data fetch after the first frame is built.
		WidgetsBinding.instance.addPostFrameCallback((_) => _updateWidgetData());
	  }

	  @override
	  void dispose() {
		_ticker.dispose();
		widget.controller.removeListener(_updateWidgetData);
		super.dispose();
	  }

	  @override
	  void didUpdateWidget(MetaballContainer oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (widget.controller != oldWidget.controller) {
		  oldWidget.controller.removeListener(_updateWidgetData);
		  widget.controller.addListener(_updateWidgetData);
		  _updateWidgetData();
		}
	  }

	  void _updateWidgetData() {
		final newWidgetData = <vm.Vector4>[];
		for (final key in widget.controller.keys) {
		  final context = key.currentContext;
		  if (context != null) {
			final renderBox = context.findRenderObject() as RenderBox?;
			if (renderBox != null && renderBox.hasSize) {
			  final size = renderBox.size;
			  final position = renderBox.localToGlobal(Offset.zero);
			  newWidgetData.add(vm.Vector4(position.dx, position.dy, size.width, size.height));
			}
		  }
		}

		if (!listEquals(_widgetData, newWidgetData)) {
		  setState(() {
			_widgetData.clear();
			_widgetData.addAll(newWidgetData);
		  });
		}
	  }

	  @override
	  Widget build(BuildContext context) {
		// This callback ensures we get the latest positions of widgets
		// that might be moving, like during drag operations.
		WidgetsBinding.instance.addPostFrameCallback((_) => _updateWidgetData());

		return Stack(
		  children: [
			Positioned.fill(
			  child: CustomPaint(
				painter: MetaballPainter(
				  shader: widget.shader,
				  time: _time,
				  widgetData: _widgetData,
				  color: widget.color,
				),
			  ),
			),
			// The actual child widgets are made invisible but remain interactive.
			// This allows users to drag them, press buttons, etc.
			Opacity(
			  opacity: 0.0,
			  child: widget.child,
			),
		  ],
		);
	  }
	}

	/// The painter that configures and runs the shader.
	class MetaballPainter extends CustomPainter {
	  final ui.FragmentShader shader;
	  final double time;
	  final List<vm.Vector4> widgetData;
	  final Color color;

	  MetaballPainter({
		required this.shader,
		required this.time,
		required this.widgetData,
		required this.color,
	  });

	  @override
	  void paint(Canvas canvas, Size size) {
		// Prepare the widget data as a flat list of floats.
		final floatList = Float32List(widgetData.length * 4);
		for (int i = 0; i < widgetData.length; i++) {
		  widgetData[i].copyIntoArray(floatList, i * 4);
		}

		// --- SET SHADER UNIFORMS ---
		// Uniforms are indexed based on their declaration order in the shader file.
		int uniformIndex = 0;

		// uniform float uTime;
		shader.setFloat(uniformIndex++, time);

		// uniform vec2 uResolution;
		shader.setFloat(uniformIndex++, size.width);
		shader.setFloat(uniformIndex++, size.height);

		// uniform int uWidgetCount; (passed as a float)
		shader.setFloat(uniformIndex++, widgetData.length.toDouble());

		// uniform vec4 uColor;
		shader.setFloat(uniformIndex++, color.red / 255.0);
		shader.setFloat(uniformIndex++, color.green / 255.0);
		shader.setFloat(uniformIndex++, color.blue / 255.0);
		shader.setFloat(uniformIndex++, color.alpha / 255.0);

		// uniform vec4 uWidgets[64];
		// This is the corrected way to pass array data.
		// We loop through our list and set each float individually.
		for (int i = 0; i < floatList.length; i++) {
		  shader.setFloat(uniformIndex++, floatList[i]);
		}

		// Draw a rectangle covering the whole screen with the configured shader.
		canvas.drawRect(
		  Rect.fromLTWH(0, 0, size.width, size.height),
		  Paint()..shader = shader,
		);
	  }

	  @override
	  bool shouldRepaint(MetaballPainter oldDelegate) {
		// Repaint if time has passed or if widget positions/sizes have changed.
		return time != oldDelegate.time || !listEquals(widgetData, oldDelegate.widgetData) || color != oldDelegate.color;
	  }
	}

	/// A helper widget that automatically registers its GlobalKey with a MetaballController.
	class MetaballChild extends StatefulWidget {
	  final MetaballController controller;
	  final Widget child;

	  const MetaballChild({
		Key? key,
		required this.controller,
		required this.child,
	  }) : super(key: key);

	  @override
	  _MetaballChildState createState() => _MetaballChildState();
	}

	class _MetaballChildState extends State<MetaballChild> {
	  final GlobalKey _key = GlobalKey();

	  @override
	  void initState() {
		super.initState();
		widget.controller.addKey(_key);
	  }

	  @override
	  void dispose() {
		widget.controller.removeKey(_key);
		super.dispose();
	  }

	  @override
	  void didUpdateWidget(MetaballChild oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (widget.controller != oldWidget.controller) {
		  oldWidget.controller.removeKey(_key);
		  widget.controller.addKey(_key);
		}
	  }

	  @override
	  Widget build(BuildContext context) {
		// The key is attached to the SizedBox, allowing us to find its
		// position and size on the screen.
		return SizedBox(
		  key: _key,
		  child: widget.child,
		);
	  }
	}

	// --- DEMO ---

	// --- NEW AND IMPROVED DEMO ---

	class MetaballDemo extends StatefulWidget {
	  final ui.FragmentShader shader;
	  const MetaballDemo({Key? key, required this.shader}) : super(key: key);

	  @override
	  _MetaballDemoState createState() => _MetaballDemoState();
	}

	class _MetaballDemoState extends State<MetaballDemo> {
	  final _controller = MetaballController();
	  
	  // State for our various demo widgets
	  Offset _draggableCirclePos = const Offset(100, 200);
	  Offset _draggableRectPos = const Offset(250, 450);
	  Offset _animatedButtonPos = const Offset(50, 400);
	  Timer? _timer;

	  @override
	  void initState() {
		super.initState();
		// Timer to drive the animation of the button
		_timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
		  final screenWidth = MediaQuery.of(context).size.width;
		  final time = timer.tick * 0.05;
		  setState(() {
			_animatedButtonPos = Offset(
			  screenWidth / 2 + (sin(time) * 100) - 40,
			  400 + (cos(time * 0.7) * 50),
			);
		  });
		});
	  }

	  @override
	  void dispose() {
		_timer?.cancel();
		super.dispose();
	  }

	  @override
	  Widget build(BuildContext context) {
		return Scaffold(
		  appBar: AppBar(
			title: const Text('Mix & Match Metaballs'),
			elevation: 0,
			backgroundColor: Colors.transparent,
		  ),
		  body: MetaballContainer(
			shader: widget.shader,
			controller: _controller,
			color: const Color(0xFFE0E0E0),
			child: Stack(
			  children: [
				// --- WIDGET 1: A Draggable Circle (Original Behavior) ---
				Positioned(
				  left: _draggableCirclePos.dx,
				  top: _draggableCirclePos.dy,
				  child: GestureDetector(
					onPanUpdate: (details) => setState(() => _draggableCirclePos += details.delta),
					child: MetaballChild(
					  controller: _controller,
					  child: Container(
						width: 120,
						height: 120,
						decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
					  ),
					),
				  ),
				),

				// --- WIDGET 2: A Draggable RECTANGLE ---
				// Notice how its blob is still circular because of our shader.
				Positioned(
				  left: _draggableRectPos.dx,
				  top: _draggableRectPos.dy,
				  child: GestureDetector(
					onPanUpdate: (details) => setState(() => _draggableRectPos += details.delta),
					child: MetaballChild(
					  controller: _controller,
					  child: Container(
						width: 150,
						height: 80,
						decoration: BoxDecoration(
						  color: Colors.black,
						  borderRadius: BorderRadius.circular(20),
						),
					  ),
					),
				  ),
				),

				// --- WIDGET 3: An ANIMATED, interactive button ---
				// This shows the effect works on widgets that move on their own.
				Positioned(
				  left: _animatedButtonPos.dx,
				  top: _animatedButtonPos.dy,
				  child: MetaballChild(
					controller: _controller,
					child: ElevatedButton(
					  onPressed: () {
						ScaffoldMessenger.of(context).showSnackBar(
						  const SnackBar(content: Text('Animated button pressed!')),
						);
					  },
					  style: ElevatedButton.styleFrom(
						backgroundColor: Colors.deepPurple,
						shape: const StadiumBorder(),
						padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
					  ),
					  child: const Text('Animate!'),
					),
				  ),
				),

				// --- WIDGET 4: A STATIC container with text ---
				// This shows how you can wrap non-moving UI elements.
				Positioned(
				  bottom: 50,
				  left: 20,
				  child: MetaballChild(
					controller: _controller,
					child: Container(
					  padding: const EdgeInsets.all(16),
					  decoration: BoxDecoration(
						color: Colors.black,
						border: Border.all(color: Colors.white),
					  ),
					  child: const Text(
						'Static Widget',
						style: TextStyle(color: Colors.white, fontSize: 18),
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

	// A simple data class for the demo blobs.
	@immutable
	class DraggableBlobInfo {
	  Offset position;
	  final double size;
	  final Color color;
	  DraggableBlobInfo(this.position, this.size, this.color);
	}
*/
	
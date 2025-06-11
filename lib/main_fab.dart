import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// --- THIS IS THE CRITICAL CHANGE ---
const int maxWidgets = 7; // MUST match #define MAX_WIDGETS in the shader
const int floatsPerWidget = 5; // x, y, width, height, radius

class WidgetGeometry {
  final Rect rect;
  final double cornerRadius;
  WidgetGeometry({required this.rect, this.cornerRadius = 0.0});

  static WidgetGeometry? fromKey(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    return WidgetGeometry(
      rect: Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
    );
  }
}

class LiquidGlassWrapper extends StatefulWidget {
  final List<Widget> children;
  final List<double> cornerRadii;
  final double blobbiness;
  const LiquidGlassWrapper({
    super.key,
    required this.children,
    this.cornerRadii = const [],
    this.blobbiness = 40.0,
  });
  @override
  State<LiquidGlassWrapper> createState() => _LiquidGlassWrapperState();
}

class _LiquidGlassWrapperState extends State<LiquidGlassWrapper>
    with SingleTickerProviderStateMixin {
  late List<GlobalKey> _keys;
  final List<WidgetGeometry> _geometries = [];
  late final Ticker _ticker;
  double _time = 0.0;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.children.length, (_) => GlobalKey());
    _loadShader();
    _ticker = createTicker(_update)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGeometries());
  }

  void _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('assets/shaders/liquid_glass.frag');
      setState(() => _shader = program.fragmentShader());
    } catch (e) {
      debugPrint('FATAL: Shader loading failed: $e');
    }
  }

  void _update(Duration elapsedTime) {
    if (!mounted) return;
    setState(() => _time = elapsedTime.inMilliseconds / 1000.0);
  }

  void _updateGeometries() {
    if (!mounted) return;
    final newGeometries = <WidgetGeometry>[];
    for (int i = 0; i < _keys.length; i++) {
      if (i >= maxWidgets) {
        debugPrint(
            'Warning: More than $maxWidgets widgets provided. Only the first $maxWidgets will be rendered with the liquid effect.');
        break;
      }
      final key = _keys[i];
      final geometry = WidgetGeometry.fromKey(key);
      if (geometry != null) {
        final radius =
            i < widget.cornerRadii.length ? widget.cornerRadii[i] : 0.0;
        newGeometries.add(WidgetGeometry(rect: geometry.rect, cornerRadius: radius));
      }
    }
    bool needsUpdate = newGeometries.length != _geometries.length ||
        _geometries.asMap().entries.any((e) => e.value.rect != newGeometries[e.key].rect);
    if (needsUpdate) {
      setState(() {
        _geometries.clear();
        _geometries.addAll(newGeometries);
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiquidGlassWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != _keys.length) {
      _keys = List.generate(widget.children.length, (_) => GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGeometries());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null || _geometries.isEmpty) {
      return _buildPlainChildren();
    }
    return ShaderMask(
      shaderCallback: (bounds) {
        final shader = _shader!;
        shader
          ..setFloat(0, bounds.width)
          ..setFloat(1, bounds.height)
          ..setFloat(2, _time)
          ..setFloat(3, widget.blobbiness)
          ..setFloat(4, _geometries.length.toDouble());

        final Float32List widgetData = Float32List(maxWidgets * floatsPerWidget);
        for (int i = 0; i < _geometries.length; i++) {
          // This check is redundant due to the _updateGeometries logic, but safe.
          if (i >= maxWidgets) break; 
          final geo = _geometries[i];
          final index = i * floatsPerWidget;
          widgetData[index + 0] = geo.rect.left;
          widgetData[index + 1] = geo.rect.top;
          widgetData[index + 2] = geo.rect.width;
          widgetData[index + 3] = geo.rect.height;
          widgetData[index + 4] = geo.cornerRadius;
        }

        // The length of widgetData is now 35 (7 * 5).
        // The loop will go from i=0 to 34.
        // shader.setFloat will be called with indices 5 through 39.
        // This is safely within the 0-42 range.
        for (int i = 0; i < widgetData.length; i++) {
          shader.setFloat(5 + i, widgetData[i]);
        }
        return shader;
      },
      child: _buildPlainChildren(),
    );
  }

  Widget _buildPlainChildren() {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _updateGeometries();
        return false;
      },
      child: Stack(
        children: List.generate(widget.children.length, (index) {
          return KeyedSubtree(key: _keys[index], child: widget.children[index]);
        }),
      ),
    );
  }
}

// --- Example Usage (Unchanged) ---
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const LiquidGlassDemoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LiquidGlassDemoScreen extends StatefulWidget {
  const LiquidGlassDemoScreen({super.key});
  @override
  State<LiquidGlassDemoScreen> createState() => _LiquidGlassDemoScreenState();
}

class _LiquidGlassDemoScreenState extends State<LiquidGlassDemoScreen> {
  Offset _ballPosition = const Offset(100, 200);
  double _blobbiness = 40.0;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Our example only uses 4 widgets, which is safely below the limit of 7.
    return Scaffold(
      backgroundColor: const Color(0xff1a1a1a),
      body: LiquidGlassWrapper(
        blobbiness: _blobbiness,
        cornerRadii: const [28, 16, 16, 30],
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            bottom: 40,
            right: _isMenuOpen ? (screenSize.width / 2 - 28) : 40,
            child: FloatingActionButton(
              onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 400),
                turns: _isMenuOpen ? 0.125 : 0.0,
                child: const Icon(Icons.add, size: 30),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.decelerate,
            bottom: _isMenuOpen ? 120 : 40,
            left: 60,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isMenuOpen ? 1.0 : 0.0,
              child: Material(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                      width: 100,
                      height: 50,
                      child: Center(child: Text('Action 1'))),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.decelerate,
            bottom: _isMenuOpen ? 120 : 40,
            right: 60,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isMenuOpen ? 1.0 : 0.0,
              child: Material(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                      width: 100,
                      height: 50,
                      child: Center(child: Text('Action 2'))),
                ),
              ),
            ),
          ),
          Positioned(
            left: _ballPosition.dx,
            top: _ballPosition.dy,
            child: Draggable(
              feedback: const SizedBox.shrink(),
              onDragUpdate: (details) =>
                  setState(() => _ballPosition += details.delta),
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                    color: Colors.purple, shape: BoxShape.circle),
                child: const Center(
                    child: Icon(Icons.drag_handle, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildControls(),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Blobbiness: ${_blobbiness.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white)),
            Slider(
              value: _blobbiness,
              min: 5.0,
              max: 150.0,
              onChanged: (val) => setState(() => _blobbiness = val),
            ),
          ],
        ),
      ),
    );
  }
}
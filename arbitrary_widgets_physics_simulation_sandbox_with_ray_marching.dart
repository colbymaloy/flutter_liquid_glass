import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

// Entry point
void main() {
  runApp(const PhysicsSandboxApp());
}

// Main application widget
class PhysicsSandboxApp extends StatelessWidget {
  const PhysicsSandboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Advanced Physics Sandbox',
      theme: ThemeData.dark().copyWith(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurpleAccent, brightness: Brightness.dark),
        highlightColor: Colors.deepPurpleAccent.withAlpha((0.2 * 255).round()),
      ),
      home: const SandboxPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Page holding the sandbox and controls
class SandboxPage extends StatefulWidget {
  const SandboxPage({super.key});

  @override
  State<SandboxPage> createState() => _SandboxPageState();
}

class _SandboxPageState extends State<SandboxPage> {
  bool _is3DEnabled = false;
  bool _isSoftBodyEnabled = false;
  bool _isRayMarchingEnabled = false;

  final GlobalKey _widgetKey = GlobalKey();
  ui.Image? _widgetImage;
  Size _widgetSize = const Size(150, 100);

  bool _captureRequested = true;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _requestCapture(isInitial: true));
  }

  void _requestCapture({bool isInitial = false}) {
    if (!mounted || _isCapturing) return;

    if (!isInitial) {
      setState(() {
        _captureRequested = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_captureRequested && mounted && !_isCapturing) {
        await _captureWidgetImage();
      }
    });
  }

  Future<void> _captureWidgetImage() async {
    if (!mounted || _widgetKey.currentContext == null || _isCapturing) {
      return;
    }
    _isCapturing = true;

    try {
      RenderRepaintBoundary boundary = _widgetKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      if (boundary.size.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) {
          _isCapturing = false;
          return;
        }
        boundary = _widgetKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary; // Re-fetch
        if (boundary.size.isEmpty) {
          // ignore: avoid_print
          print(
              "Widget boundary size still zero after delay, aborting capture.");
          _isCapturing = false;
          if (mounted) setState(() => _captureRequested = false);
          return;
        }
      }

      if (boundary.debugNeedsPaint) {
        // ignore: avoid_print
        print("Boundary needs paint, deferring capture for next frame.");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _isCapturing = false;
            _requestCapture(); // Try again next frame
          }
        });
        return;
      }

      final newWidgetSize = boundary.size;
      if (!mounted) {
        _isCapturing = false;
        return;
      }
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      ui.Image image = await boundary.toImage(pixelRatio: devicePixelRatio);

      if (mounted) {
        setState(() {
          _widgetImage = image;
          _widgetSize = Size(newWidgetSize.width, newWidgetSize.height);
          _captureRequested = false;
        });
      } else {
        image.dispose();
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error capturing widget image: $e");
    } finally {
      if (mounted) {
        _isCapturing = false;
      }
    }
  }

  Widget _buildTargetWidget() {
    return RepaintBoundary(
      key: _widgetKey,
      child: Container(
        width: _widgetSize.width,
        height: _widgetSize.height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFDC830), Color(0xFFF37335)], // Sunny Orange
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.3 * 255).round()),
              blurRadius: 10,
              offset: const Offset(5, 5),
            )
          ],
        ),
        child: Center(
          child: Text(
            'FLUTTER\nDYNAMIC',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _isSoftBodyEnabled ? 15 : 22,
                shadows: const [
                  Shadow(
                      blurRadius: 2,
                      color: Colors.black45,
                      offset: Offset(1, 1))
                ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_widgetImage == null &&
        !_captureRequested &&
        mounted &&
        !_isCapturing) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _requestCapture(isInitial: true));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Physics Sandbox Omega'),
        elevation: 4,
      ),
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: InteractiveViewerWidget(
              is3DEnabled: _is3DEnabled,
              isSoftBodyEnabled: _isSoftBodyEnabled,
              isRayMarchingEnabled: _isRayMarchingEnabled,
              widgetImage: _widgetImage,
              widgetSize: _widgetSize,
              key: ValueKey(
                  '${_widgetImage?.hashCode}_${_widgetSize.hashCode}_$_isSoftBodyEnabled$_is3DEnabled$_isRayMarchingEnabled'),
            ),
          ),
          Offstage(
              offstage: !(_captureRequested || _widgetImage == null),
              child: _buildTargetWidget()),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Wrap(
        spacing: 10.0,
        runSpacing: 6.0,
        alignment: WrapAlignment.center,
        children: [
          FilterChip(
            label: Text(_is3DEnabled ? 'View: 3D' : 'View: 2D'),
            selected: _is3DEnabled,
            onSelected: (bool value) => setState(() => _is3DEnabled = value),
            avatar: Icon(
                _is3DEnabled ? Icons.threed_rotation : Icons.crop_square,
                color: _is3DEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : null),
          ),
          FilterChip(
            label: Text(_isSoftBodyEnabled ? 'Body: Soft' : 'Body: Rigid'),
            selected: _isSoftBodyEnabled,
            onSelected: (bool value) {
              setState(() => _isSoftBodyEnabled = value);
              _requestCapture();
            },
            avatar: Icon(
                _isSoftBodyEnabled ? Icons.waves : Icons.rectangle_outlined,
                color: _isSoftBodyEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : null),
          ),
          FilterChip(
            label: Text(
                _isRayMarchingEnabled ? 'Ray March: ON' : 'Ray March: OFF'),
            selected: _isRayMarchingEnabled,
            onSelected: (bool value) =>
                setState(() => _isRayMarchingEnabled = value),
            avatar: Icon(_isRayMarchingEnabled ? Icons.blur_on : Icons.mouse,
                color: _isRayMarchingEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : null),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.aspect_ratio),
            label: const Text('Resize & Recapture'),
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            onPressed: () {
              _captureRequested = true;
              final newWidth = math
                  .max(
                      50.0,
                      _widgetSize.width +
                          (math.Random().nextDouble() * 100.0 - 50.0))
                  .toDouble();
              final newHeight = math
                  .max(
                      50.0,
                      _widgetSize.height +
                          (math.Random().nextDouble() * 60.0 - 30.0))
                  .toDouble();
              setState(() {
                _widgetSize = Size(newWidth, newHeight);
              });
              _requestCapture();
            },
          ),
        ],
      ),
    );
  }
}

class InteractiveViewerWidget extends StatefulWidget {
  final bool is3DEnabled;
  final bool isSoftBodyEnabled;
  final bool isRayMarchingEnabled;
  final ui.Image? widgetImage;
  final Size widgetSize;

  const InteractiveViewerWidget({
    super.key,
    required this.is3DEnabled,
    required this.isSoftBodyEnabled,
    required this.isRayMarchingEnabled,
    this.widgetImage,
    required this.widgetSize,
  });

  @override
  State<InteractiveViewerWidget> createState() =>
      _InteractiveViewerWidgetState();

  static const double gravity = 280.0;
  static const double stiffness = 1500.0;
  static const double dampingCoefficient = 18.0;
  static const double particleMass = 1.0;
  static const int softBodyGridSize = 10;
  static const double restitution = 0.35;
}

class _InteractiveViewerWidgetState extends State<InteractiveViewerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Particle> _particles = [];
  final List<Spring> _springs = [];

  vm.Vector2 _rigidBodyPosition = vm.Vector2.zero();
  double _rigidBodyAngle = 0.0;
  double _rigidBodyAngularVelocity = 0.0;

  final vm.Matrix4 _projectionMatrix = vm.Matrix4.identity();
  final vm.Matrix4 _viewMatrix = vm.Matrix4.identity();

  vm.Vector2? _pointerLocation;
  bool _isDragging = false;
  Particle? _draggedParticle;
  vm.Vector2 _dragOffset = vm.Vector2.zero();

  final vm.Vector3 _rayMarchCamPos = vm.Vector3(0, 0, -3.5);
  vm.Vector2 _rayMarchMouse = vm.Vector2(0.5, 0.5); // Initialized to center

  Size _painterSize = Size.zero;

  // For ray marching snapshot
  ui.Image? _rayMarchSnapshot;
  bool _rayMarchNeedsUpdate = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 999),
    )..addListener(() {
        _updateSimulation(1.0 / 60.0);
        if (mounted) {
          setState(() {});
        }
      });

    if (widget.widgetImage != null && widget.widgetSize != Size.zero) {
      _initializeEntities();
    }
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant InteractiveViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.widgetImage != oldWidget.widgetImage ||
        widget.widgetSize != oldWidget.widgetSize ||
        widget.isSoftBodyEnabled != oldWidget.isSoftBodyEnabled ||
        widget.is3DEnabled != oldWidget.is3DEnabled ||
        (widget.isRayMarchingEnabled != oldWidget.isRayMarchingEnabled &&
            widget.isRayMarchingEnabled) || // If ray marching just turned on
        (widget.widgetImage != null && oldWidget.widgetImage == null)) {
      if (widget.isRayMarchingEnabled) {
        _rayMarchNeedsUpdate =
            true; // Request update if RM toggled on or other params change
      }

      if (widget.widgetImage != null && widget.widgetSize != Size.zero) {
        _initializeEntities();
      } else {
        _particles.clear();
        _springs.clear();
      }
    }
vm.Vector2? previousPointerLocation;

if (widget.isRayMarchingEnabled &&
    _pointerLocation != previousPointerLocation) {
  // Do your update
  previousPointerLocation = _pointerLocation;
}
  }

  void _initializeEntities() {
    _particles.clear();
    _springs.clear();

    if (widget.widgetImage == null ||
        widget.widgetSize == Size.zero ||
        _painterSize == Size.zero) {
      return;
    }
    _rayMarchNeedsUpdate = true; // Also re-render raymarch if entities re-init

    final center = vm.Vector2(0, -_painterSize.height * 0.2);

    if (widget.isSoftBodyEnabled) {
      _initSoftBody(center, widget.widgetSize);
    } else {
      _initRigidBody(center);
    }
  }

  void _initRigidBody(vm.Vector2 center) {
    _rigidBodyPosition = center.clone();
    _rigidBodyAngle = 0.0;
    _rigidBodyAngularVelocity = 0.0;

    _particles.add(Particle(
        position: center.clone(),
        mass: InteractiveViewerWidget.particleMass * 10,
        isFixed: false));
  }

  void _initSoftBody(vm.Vector2 center, Size size) {
    final double spacingX =
        size.width / (InteractiveViewerWidget.softBodyGridSize - 1);
    final double spacingY =
        size.height / (InteractiveViewerWidget.softBodyGridSize - 1);
    final vm.Vector2 offset =
        vm.Vector2(-size.width / 2, -size.height / 2) + center;

    bool makeMiddleTopFixed = true;

    for (int y = 0; y < InteractiveViewerWidget.softBodyGridSize; y++) {
      for (int x = 0; x < InteractiveViewerWidget.softBodyGridSize; x++) {
        final pos = vm.Vector2(x * spacingX, y * spacingY) + offset;
        bool isFixed = false;
        if (y == 0 &&
            (x == 0 || x == InteractiveViewerWidget.softBodyGridSize - 1)) {
          isFixed = true;
        }
        if (y == 0 &&
            x == (InteractiveViewerWidget.softBodyGridSize - 1) ~/ 2 &&
            makeMiddleTopFixed) {
          isFixed = true;
        }

        _particles.add(Particle(
            position: pos.clone(),
            originalPosition: pos.clone(),
            mass: InteractiveViewerWidget.particleMass,
            isFixed: isFixed));
      }
    }

    for (int y = 0; y < InteractiveViewerWidget.softBodyGridSize; y++) {
      for (int x = 0; x < InteractiveViewerWidget.softBodyGridSize; x++) {
        int currentIndex = y * InteractiveViewerWidget.softBodyGridSize + x;
        if (x < InteractiveViewerWidget.softBodyGridSize - 1) {
          _springs.add(Spring(
              _particles[currentIndex],
              _particles[currentIndex + 1],
              InteractiveViewerWidget.stiffness,
              InteractiveViewerWidget.dampingCoefficient));
        }
        if (y < InteractiveViewerWidget.softBodyGridSize - 1) {
          _springs.add(Spring(
              _particles[currentIndex],
              _particles[
                  currentIndex + InteractiveViewerWidget.softBodyGridSize],
              InteractiveViewerWidget.stiffness,
              InteractiveViewerWidget.dampingCoefficient));
        }
        if (x < InteractiveViewerWidget.softBodyGridSize - 1 &&
            y < InteractiveViewerWidget.softBodyGridSize - 1) {
          _springs.add(Spring(
              _particles[currentIndex],
              _particles[
                  currentIndex + InteractiveViewerWidget.softBodyGridSize + 1],
              InteractiveViewerWidget.stiffness * 0.8,
              InteractiveViewerWidget.dampingCoefficient));
          _springs.add(Spring(
              _particles[currentIndex + 1],
              _particles[
                  currentIndex + InteractiveViewerWidget.softBodyGridSize],
              InteractiveViewerWidget.stiffness * 0.8,
              InteractiveViewerWidget.dampingCoefficient));
        }
      }
    }
  }

  void _updateSimulation(double dt) {
    if (widget.widgetImage == null ||
        _painterSize == Size.zero ||
        (_particles.isEmpty && !widget.isRayMarchingEnabled)) {
      // Allow update if only ray marching
      return;
    }

    if (widget.isRayMarchingEnabled && _rayMarchNeedsUpdate && mounted) {
      // Generate snapshot for ray marching
      // This will be done in the painter for simplicity now, triggered by flag
    }

    if (_particles.isNotEmpty) {
      // Only run physics if particles exist
      for (var particle in _particles) {
        if (!particle.isFixed) {
          particle.applyForce(
              vm.Vector2(0, InteractiveViewerWidget.gravity * particle.mass));
        }
      }

      if (widget.isSoftBodyEnabled) {
        for (var spring in _springs) {
          spring.applyForce();
        }
        if (_isDragging &&
            _draggedParticle != null &&
            _pointerLocation != null) {
          final targetPosition = _pointerLocation! + _dragOffset;
          final dragForce = (targetPosition - _draggedParticle!.position) *
              (InteractiveViewerWidget.stiffness * 8);
          _draggedParticle!.applyForce(dragForce);
          _draggedParticle!.velocity =
              (targetPosition - _draggedParticle!.position) * (10.0);
        }
      } else {
        if (_isDragging &&
            _draggedParticle != null &&
            _pointerLocation != null) {
          final targetPosition = _pointerLocation! + _dragOffset;
          final dragForce = (targetPosition - _draggedParticle!.position) *
              (InteractiveViewerWidget.stiffness * 0.5);
          _draggedParticle!.applyForce(dragForce);
          _draggedParticle!.velocity =
              (targetPosition - _draggedParticle!.position) * (5.0);

          vm.Vector2 leverArm = targetPosition - _draggedParticle!.position;
          double torque = leverArm
              .cross((targetPosition - _draggedParticle!.position) * 0.1);
          _rigidBodyAngularVelocity +=
              torque * 0.005 / (_draggedParticle!.mass * 0.1);
        }
        _rigidBodyAngle += _rigidBodyAngularVelocity * dt;
        _rigidBodyAngularVelocity *= (1.0 - 0.1 * dt);
      }

      for (var particle in _particles) {
        particle.update(dt);
      }

      if (!widget.isSoftBodyEnabled) {
        _rigidBodyPosition.setFrom(_particles.first.position);
      }

      // Constraints
      final halfWidth = _painterSize.width / 2;
      final halfHeight = _painterSize.height / 2;
      final double objHalfWidth = widget.widgetSize.width / 2;
      final double objHalfHeight = widget.widgetSize.height / 2;

      for (var particle in _particles) {
        if (particle.isFixed) continue;
        double effectiveParticleRadiusY =
            widget.isSoftBodyEnabled ? 5.0 : objHalfHeight * 0.8;
        double effectiveParticleRadiusX =
            widget.isSoftBodyEnabled ? 5.0 : objHalfWidth * 0.8;

        // Floor, Ceiling, Walls (simplified)
        if (particle.position.y > halfHeight - effectiveParticleRadiusY) {
          particle.position.y = halfHeight - effectiveParticleRadiusY;
          particle.previousPosition.y = particle.position.y +
              (particle.position.y - particle.previousPosition.y) *
                  -InteractiveViewerWidget.restitution;
          if (!widget.isSoftBodyEnabled) _rigidBodyAngularVelocity *= 0.95;
        } else if (particle.position.y <
            -halfHeight + effectiveParticleRadiusY) {
          particle.position.y = -halfHeight + effectiveParticleRadiusY;
          particle.previousPosition.y = particle.position.y +
              (particle.position.y - particle.previousPosition.y) *
                  -InteractiveViewerWidget.restitution;
        }
        if (particle.position.x > halfWidth - effectiveParticleRadiusX) {
          particle.position.x = halfWidth - effectiveParticleRadiusX;
          particle.previousPosition.x = particle.position.x +
              (particle.position.x - particle.previousPosition.x) *
                  -InteractiveViewerWidget.restitution;
        } else if (particle.position.x <
            -halfWidth + effectiveParticleRadiusX) {
          particle.position.x = -halfWidth + effectiveParticleRadiusX;
          particle.previousPosition.x = particle.position.x +
              (particle.position.x - particle.previousPosition.x) *
                  -InteractiveViewerWidget.restitution;
        }
      }
      if (!widget.isSoftBodyEnabled) {
        _particles.first.position.setFrom(_rigidBodyPosition);
        // _particles.first.previousPosition = _rigidBodyPosition - (_particles.first.velocity * dt) ; This line was problematic, verlet handles it implicitly.
      }
    }

    if (widget.is3DEnabled) {
      final aspect = _painterSize.width /
          (_painterSize.height.abs() < 0.001 ? 1.0 : _painterSize.height);
      if (aspect > 0) {
        vm.setPerspectiveMatrix(
            _projectionMatrix, vm.radians(60.0), aspect, 0.1, 1000.0);
      }
      _viewMatrix.setIdentity();
      _viewMatrix.translate(0.0, -widget.widgetSize.height * 0.3,
          -(widget.widgetSize.width * 1.8));
      _viewMatrix.rotateX(vm.radians(15));
      if (_isDragging &&
          _pointerLocation != null &&
          !widget.isRayMarchingEnabled) {
        _viewMatrix.rotateY(vm.radians(
            (_pointerLocation!.x / _painterSize.width * 180 - 90) * 0.2));
      }
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_painterSize == Size.zero) {
      return; // Guard against uninitialized painterSize
    }

    final localPos = vm.Vector2(
      event.localPosition.dx - _painterSize.width / 2,
      event.localPosition.dy - _painterSize.height / 2,
    );

    setState(() {
      _isDragging = true;
      _pointerLocation = localPos;

      if (widget.isRayMarchingEnabled) {
        _rayMarchMouse = vm.Vector2(event.localPosition.dx / _painterSize.width,
            event.localPosition.dy / _painterSize.height);
        _draggedParticle = null;
        _rayMarchNeedsUpdate = true; // Request new snapshot on click/drag start
        return;
      }

      if (widget.widgetImage == null) return; // Guard for physics interaction

      if (widget.isSoftBodyEnabled) {
        _draggedParticle = _findClosestParticle(localPos);
        if (_draggedParticle != null) {
          _dragOffset = _draggedParticle!.position - localPos;
          _draggedParticle!.velocity.setZero();
          _draggedParticle!.previousPosition
              .setFrom(_draggedParticle!.position);
        }
      } else if (_particles.isNotEmpty) {
        vm.Matrix4 transform = vm.Matrix4.identity()
          ..translate(_rigidBodyPosition.x, _rigidBodyPosition.y)
          ..rotateZ(_rigidBodyAngle);

        vm.Matrix4 invertedTransform = vm.Matrix4.copy(transform);
        invertedTransform.invert();

        vm.Vector3 clickInBodySpace =
            invertedTransform.transform3(vm.Vector3(localPos.x, localPos.y, 0));

        if (clickInBodySpace.x.abs() < widget.widgetSize.width / 2 &&
            clickInBodySpace.y.abs() < widget.widgetSize.height / 2) {
          _draggedParticle = _particles.first;
          _dragOffset = _draggedParticle!.position - localPos;
          _particles.first.velocity.setZero();
          _particles.first.previousPosition.setFrom(_particles.first.position);
          _rigidBodyAngularVelocity = 0;
        } else {
          _draggedParticle = null;
        }
      }

      if (_draggedParticle == null && !widget.isRayMarchingEnabled) {
        Particle? target = widget.isSoftBodyEnabled
            ? _findClosestParticle(localPos)
            : (_particles.isNotEmpty ? _particles.first : null);
        if (target != null) {
          final impulseDirection = (target.position - localPos).normalized();
          target.applyImpulse(impulseDirection * 300.0);
          if (!widget.isSoftBodyEnabled) {
            double torque =
                (localPos - target.position).cross(impulseDirection);
            _rigidBodyAngularVelocity += torque * 0.1;
          }
        }
      }
    });
  }

  Particle? _findClosestParticle(vm.Vector2 point) {
    if (_particles.isEmpty) return null;
    Particle? closest;
    double minDistSq = double.infinity;
    for (var p in _particles) {
      if (p.isFixed) {
        continue;
      }
      final distSq = p.position.distanceToSquared(point);
      if (distSq < minDistSq) {
        minDistSq = distSq;
        closest = p;
      }
    }
    return (minDistSq <
            math.pow(
                widget.isSoftBodyEnabled ? 40 : (widget.widgetSize.width / 1.5),
                2))
        ? closest
        : null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDragging || _painterSize == Size.zero) return;

    final localPos = vm.Vector2(
      event.localPosition.dx - _painterSize.width / 2,
      event.localPosition.dy - _painterSize.height / 2,
    );
    setState(() {
      _pointerLocation = localPos;
      if (widget.isRayMarchingEnabled) {
        _rayMarchMouse = vm.Vector2(event.localPosition.dx / _painterSize.width,
            event.localPosition.dy / _painterSize.height);
        _rayMarchNeedsUpdate = true; // Request new snapshot on drag
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isDragging) return;
    setState(() {
      _isDragging = false;
      _draggedParticle = null;
      if (widget.isRayMarchingEnabled) {
        _rayMarchNeedsUpdate = true; // Final update on release if desired
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show circular progress if widgetImage is truly needed and not available
    // Ray marching can proceed without widgetImage.
    if (!widget.isRayMarchingEnabled &&
        (widget.widgetImage == null || widget.widgetSize == Size.zero)) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(builder: (context, constraints) {
      _painterSize = constraints.biggest;
      // Initialize entities if painter size is now valid and they haven't been
      if ((_painterSize != Size.zero) &&
          _particles.isEmpty && // only if particles are not yet initialized
          !widget.isRayMarchingEnabled && // and not in raymarching only mode
          widget.widgetImage != null) {
        // and image is available
        _initializeEntities();
      } else if (_painterSize != Size.zero &&
          widget.isRayMarchingEnabled &&
          _rayMarchSnapshot == null &&
          _rayMarchNeedsUpdate) {
        // Initial trigger for ray march snapshot if needed and painter size available
        // The actual generation is handled by the painter via the flag
      }

      return Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: CustomPaint(
          size: _painterSize,
          painter: SimulationPainter(
              is3DEnabled: widget.is3DEnabled,
              isSoftBodyEnabled: widget.isSoftBodyEnabled,
              isRayMarchingEnabled: widget.isRayMarchingEnabled,
              widgetImage: widget.widgetImage, // Can be null if ray marching
              widgetSize: widget.widgetSize,
              particles: _particles,
              springs: _springs,
              rigidBodyPosition: _rigidBodyPosition,
              rigidBodyAngle: _rigidBodyAngle,
              projectionMatrix: _projectionMatrix,
              viewMatrix: _viewMatrix,
              pointerLocation: _pointerLocation,
              rayMarchCamPos: _rayMarchCamPos,
              rayMarchMouse: _rayMarchMouse,
              lightDirection: vm.Vector3(0.6, -0.8, -1.0)..normalize(),
              // Pass snapshot and update mechanism for ray marching
              rayMarchSnapshot: _rayMarchSnapshot,
              rayMarchNeedsUpdate: _rayMarchNeedsUpdate,
              onRayMarchSnapshotUpdated: (ui.Image? newSnapshot) {
                if (mounted && widget.isRayMarchingEnabled) {
                  // Check if still relevant
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Update state after frame
                    if (mounted) {
                      // Double check mounted status
                      setState(() {
                        _rayMarchSnapshot = newSnapshot;
                        _rayMarchNeedsUpdate = false; // Reset flag
                      });
                    } else {
                      newSnapshot?.dispose(); // Dispose if not mounted
                    }
                  });
                } else {
                  newSnapshot
                      ?.dispose(); // Dispose if raymarching was turned off
                }
              }),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _rayMarchSnapshot?.dispose();
    super.dispose();
  }
}

class Particle {
  vm.Vector2 position;
  vm.Vector2 previousPosition;
  vm.Vector2 velocity;
  final vm.Vector2 _forceAccumulator;
  double mass;
  double invMass;
  bool isFixed;
  vm.Vector2 originalPosition;

  Particle(
      {required this.position,
      vm.Vector2? originalPosition,
      this.mass = 1.0,
      this.isFixed = false})
      : previousPosition = position.clone(),
        velocity = vm.Vector2.zero(),
        _forceAccumulator = vm.Vector2.zero(),
        invMass = (mass == 0 || isFixed) ? 0.0 : 1.0 / mass,
        originalPosition = originalPosition?.clone() ?? position.clone();

  void applyForce(vm.Vector2 force) {
    if (isFixed) return;
    _forceAccumulator.add(force);
  }

  void applyImpulse(vm.Vector2 impulse) {
    if (isFixed) return;
    velocity.add(impulse * invMass);
    // previousPosition.sub(impulse * invMass * (1.0 / 60.0)); // This can be tricky with Verlet. Better to let velocity integrate.
  }

  void update(double dt) {
    if (isFixed) {
      _forceAccumulator.setZero();
      velocity.setZero();
      return;
    }

    vm.Vector2 currentImplicitVelocity = position - previousPosition;
    vm.Vector2 totalVelocity = currentImplicitVelocity +
        (velocity * dt); // Add explicit velocity contributions

    // Damping (applied to total current velocity for the step)
    totalVelocity.scale(math.max(0.0, 1.0 - 0.05 * dt));

    vm.Vector2 acceleration = _forceAccumulator * invMass;
    vm.Vector2 nextPosition =
        position + totalVelocity + acceleration * (dt * dt);

    previousPosition.setFrom(position);
    position.setFrom(nextPosition);
    _forceAccumulator.setZero();
    velocity.setZero(); // Explicit velocity is consumed per step
  }
}

class Spring {
  final Particle p1;
  final Particle p2;
  final double restLength;
  final double stiffness;
  final double damping;

  Spring(this.p1, this.p2, this.stiffness, this.damping)
      : restLength = p1.position.distanceTo(p2.position);

  void applyForce() {
    vm.Vector2 deltaPos = p2.position - p1.position;
    double currentLength = deltaPos.length;
    if (currentLength == 0) return;

    vm.Vector2 forceDirection = deltaPos / currentLength;

    double displacement = currentLength - restLength;
    vm.Vector2 springForce = forceDirection * (displacement * stiffness);

    vm.Vector2 v1 = (p1.position - p1.previousPosition);
    vm.Vector2 v2 = (p2.position - p2.previousPosition);
    vm.Vector2 relativeVelocity = v2 - v1;

    double dampingEffect = relativeVelocity.dot(forceDirection);
    vm.Vector2 dampingForce = forceDirection * (dampingEffect * damping);

    vm.Vector2 totalForce = springForce + dampingForce;

    p1.applyForce(totalForce);
    p2.applyForce(-totalForce);
  }
}

vm.Vector3 _reflectVector(vm.Vector3 v, vm.Vector3 n) {
  return v - n * (2.0 * v.dot(n));
}

class SimulationPainter extends CustomPainter {
  final bool is3DEnabled;
  final bool isSoftBodyEnabled;
  final bool isRayMarchingEnabled;
  final ui.Image? widgetImage; // Now nullable for ray marching only mode
  final Size widgetSize;

  final List<Particle> particles;
  final List<Spring> springs;

  final vm.Vector2 rigidBodyPosition;
  final double rigidBodyAngle;

  final vm.Matrix4 projectionMatrix;
  final vm.Matrix4 viewMatrix;
  final vm.Vector3 lightDirection;

  final vm.Vector2? pointerLocation;
  final vm.Vector3 rayMarchCamPos;
  final vm.Vector2 rayMarchMouse;

  // Ray Marching Snapshot related
  final ui.Image? rayMarchSnapshot;
  final bool rayMarchNeedsUpdate;
  final Function(ui.Image? newSnapshot) onRayMarchSnapshotUpdated;

  SimulationPainter({
    required this.is3DEnabled,
    required this.isSoftBodyEnabled,
    required this.isRayMarchingEnabled,
    this.widgetImage,
    required this.widgetSize,
    required this.particles,
    required this.springs,
    required this.rigidBodyPosition,
    required this.rigidBodyAngle,
    required this.projectionMatrix,
    required this.viewMatrix,
    required this.lightDirection,
    this.pointerLocation,
    required this.rayMarchCamPos,
    required this.rayMarchMouse,
    required this.rayMarchSnapshot,
    required this.rayMarchNeedsUpdate,
    required this.onRayMarchSnapshotUpdated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    if (isRayMarchingEnabled) {
      // Drastically reduce ray marching quality for performance
      // This is the "snapshot" approach: generate only if needed.
      if (rayMarchNeedsUpdate) {
        // ignore: avoid_print
        print("Ray marching update triggered...");
        _generateRayMarchingSnapshot(
          Size(
              math.min(size.width, size.height) *
                  0.75, // Slightly larger demo area
              math.min(size.width, size.height) * 0.75),
          // Reduced resolution for performance
          64, // RM Pixel Width
          64, // RM Pixel Height
        ); // Callback will update state with new snapshot
      }
      if (rayMarchSnapshot != null) {
        // Draw the existing snapshot
        final Rect dstRect = Rect.fromCenter(
          center: Offset.zero, // Draw centered in the translated canvas
          width: math.min(size.width, size.height) * 0.75,
          height: math.min(size.width, size.height) * 0.75,
        );
        canvas.drawImageRect(
            rayMarchSnapshot!,
            Rect.fromLTWH(0, 0, rayMarchSnapshot!.width.toDouble(),
                rayMarchSnapshot!.height.toDouble()),
            dstRect,
            paint);
      } else if (rayMarchNeedsUpdate) {
        // Show a placeholder or loading for ray marching if snapshot is pending
        paint.color = Colors.grey.withAlpha(127);
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: 100, height: 100),
            paint);
        // Text inside placeholder could be added too.
      }
    } else {
      // Normal physics rendering only if widgetImage is available
      if (widgetImage != null) {
        if (isSoftBodyEnabled) {
          _drawSoftBody(canvas, size, paint);
        } else {
          _drawRigidBody(canvas, size, paint);
        }
      }
    }

    if (pointerLocation != null &&
        !isRayMarchingEnabled &&
        widgetImage != null) {
      paint.color = Colors.redAccent.withAlpha((0.7 * 255).round());
      canvas.drawCircle(
          Offset(pointerLocation!.x, pointerLocation!.y), 8, paint);
    }
    canvas.restore();
  }

  void _drawRigidBody(Canvas canvas, Size canvasSize, Paint paint) {
    if (particles.isEmpty || widgetImage == null) return; // Guard widgetImage

    final currentPosition = particles.first.position;
    final Rect imageSrcRect = Rect.fromLTWH(
        0, 0, widgetImage!.width.toDouble(), widgetImage!.height.toDouble());
    final Rect widgetDstRect = Rect.fromLTWH(-widgetSize.width / 2,
        -widgetSize.height / 2, widgetSize.width, widgetSize.height);

    canvas.save();
    if (is3DEnabled) {
      vm.Matrix4 modelMatrix = vm.Matrix4.identity()
        ..translate(currentPosition.x, currentPosition.y, 0.0)
        ..rotateZ(rigidBodyAngle);
      vm.Matrix4 modelViewMatrix = viewMatrix * modelMatrix;
      vm.Matrix4 mvp = projectionMatrix * modelViewMatrix;
      vm.Vector3 quadNormalViewSpace =
          modelViewMatrix.transform3(vm.Vector3(0, 0, 1))..normalize();
      double diffuseIntensity =
          math.max(0.0, quadNormalViewSpace.dot(lightDirection));
      double ambientIntensity = 0.3;
      double lightVal =
          ui.clampDouble(diffuseIntensity + ambientIntensity, 0.0, 1.0);

      final Float32List vertexPositions = Float32List(4 * 2);
      final List<vm.Vector3> localVerts = [
        vm.Vector3(-widgetSize.width / 2, -widgetSize.height / 2, 0),
        vm.Vector3(widgetSize.width / 2, -widgetSize.height / 2, 0),
        vm.Vector3(widgetSize.width / 2, widgetSize.height / 2, 0),
        vm.Vector3(-widgetSize.width / 2, widgetSize.height / 2, 0),
      ];
      for (int i = 0; i < 4; ++i) {
        vm.Vector4 clipSpacePos = mvp.transform(
            vm.Vector4(localVerts[i].x, localVerts[i].y, localVerts[i].z, 1.0));
        if (clipSpacePos.w.abs() < 0.0001) {
          clipSpacePos.w = 0.0001 * clipSpacePos.w.sign;
        }
        vertexPositions[i * 2] =
            (clipSpacePos.x / clipSpacePos.w) * canvasSize.width / 2.0;
        vertexPositions[i * 2 + 1] =
            (-clipSpacePos.y / clipSpacePos.w) * canvasSize.height / 2.0;
      }
      final Float32List textureCoordinates = Float32List.fromList([
        0.0,
        0.0,
        widgetImage!.width.toDouble(),
        0.0,
        widgetImage!.width.toDouble(),
        widgetImage!.height.toDouble(),
        0.0,
        widgetImage!.height.toDouble(),
      ]);
      final int rVal = (255 * lightVal).toInt();
      final int gVal = (255 * lightVal).toInt();
      final int bVal = (255 * lightVal).toInt();
      final int colorInt = (255 << 24) | (bVal << 16) | (gVal << 8) | rVal;
      final Int32List colors = Int32List(4);
      for (int i = 0; i < 4; ++i) {
        colors[i] = colorInt;
      }
      final Uint16List indices = Uint16List.fromList(const [0, 1, 2, 0, 2, 3]);
      final ui.Vertices vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        vertexPositions,
        textureCoordinates: textureCoordinates,
        colors: colors,
        indices: indices,
      );
      paint.shader = ui.ImageShader(widgetImage!, TileMode.clamp,
          TileMode.clamp, Matrix4.identity().storage);
      canvas.drawVertices(vertices, BlendMode.modulate, paint);
    } else {
      canvas.translate(currentPosition.x, currentPosition.y);
      canvas.rotate(rigidBodyAngle);
      canvas.drawImageRect(widgetImage!, imageSrcRect, widgetDstRect, paint);
    }
    canvas.restore();
  }

  void _drawSoftBody(Canvas canvas, Size canvasSize, Paint paint) {
    if (particles.length < 4 || widgetImage == null) {
      return; // Guard widgetImage
    }

    const int gridSize = InteractiveViewerWidget.softBodyGridSize;
    final Float32List vertexPositions = Float32List(gridSize * gridSize * 2);
    final Float32List textureCoordinates = Float32List(gridSize * gridSize * 2);
    final Int32List? vertexColors =
        is3DEnabled ? Int32List(gridSize * gridSize) : null;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final int particleIdx = y * gridSize + x;
        final Particle p = particles[particleIdx];
        double screenX = p.position.x;
        double screenY = p.position.y;

        if (is3DEnabled) {
          vm.Vector3 normal = vm.Vector3(0, 0, 1);
          vm.Matrix3 viewRotation = viewMatrix.getRotation();
          vm.Vector3 viewNormal = viewRotation.transform(normal)..normalize();
          double diffuseIntensity =
              math.max(0.0, viewNormal.dot(lightDirection));
          double ambientIntensity = 0.4;
          double lightVal =
              ui.clampDouble(diffuseIntensity + ambientIntensity, 0.0, 1.0);
          final int rVal = (255 * lightVal).toInt();
          final int gVal = (255 * lightVal).toInt();
          final int bVal = (255 * lightVal).toInt();
          vertexColors![particleIdx] =
              (255 << 24) | (bVal << 16) | (gVal << 8) | rVal;
          vm.Matrix4 mvp = projectionMatrix * viewMatrix;
          vm.Vector4 projected =
              mvp.transform(vm.Vector4(p.position.x, p.position.y, 0, 1.0));
          if (projected.w.abs() < 0.0001) {
            projected.w = 0.0001 * projected.w.sign;
          }
          screenX = (projected.x / projected.w) * canvasSize.width / 2.0;
          screenY = (-projected.y / projected.w) * canvasSize.height / 2.0;
        }
        vertexPositions[(particleIdx * 2)] = screenX;
        vertexPositions[(particleIdx * 2) + 1] = screenY;
        textureCoordinates[(particleIdx * 2)] =
            (x / (gridSize - 1.0)) * widgetImage!.width;
        textureCoordinates[(particleIdx * 2) + 1] =
            (y / (gridSize - 1.0)) * widgetImage!.height;
      }
    }
    const int numQuads = (InteractiveViewerWidget.softBodyGridSize - 1) *
        (InteractiveViewerWidget.softBodyGridSize - 1);
    final Uint16List indices = Uint16List(numQuads * 6);
    int quadIdx = 0;
    for (int y = 0; y < gridSize - 1; y++) {
      for (int x = 0; x < gridSize - 1; x++) {
        final int topLeft = y * gridSize + x;
        final int topRight = topLeft + 1;
        final int bottomLeft = (y + 1) * gridSize + x;
        final int bottomRight = bottomLeft + 1;
        indices[quadIdx * 6 + 0] = topLeft.toUnsigned(16);
        indices[quadIdx * 6 + 1] = topRight.toUnsigned(16);
        indices[quadIdx * 6 + 2] = bottomLeft.toUnsigned(16);
        indices[quadIdx * 6 + 3] = topRight.toUnsigned(16);
        indices[quadIdx * 6 + 4] = bottomRight.toUnsigned(16);
        indices[quadIdx * 6 + 5] = bottomLeft.toUnsigned(16);
        quadIdx++;
      }
    }
    final ui.Vertices vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      vertexPositions,
      textureCoordinates: textureCoordinates,
      colors: vertexColors,
      indices: indices,
    );
    paint.shader = ui.ImageShader(widgetImage!, TileMode.clamp, TileMode.clamp,
        Matrix4.identity().storage);
    canvas.drawVertices(
        vertices, is3DEnabled ? BlendMode.modulate : BlendMode.dst, paint);
  }

  // Generates the ray marching image and calls the callback.
  // This should be called off the main paint path if possible, or made very fast.
  // For this demo, it's called from paint if rayMarchNeedsUpdate is true.
  void _generateRayMarchingSnapshot(
      Size demoSize, int rmPixelWidth, int rmPixelHeight) {
    // This function is now synchronous and will block the paint path.
    // For true async, this would need to be in an isolate.
    final int pWidth = rmPixelWidth;
    final int pHeight = rmPixelHeight;
    if (pWidth <= 0 || pHeight <= 0) {
      onRayMarchSnapshotUpdated(null);
      return;
    }

    final Uint8List pixels = Uint8List(pWidth * pHeight * 4);
    vm.Vector3 lightDir = vm.Vector3(
        rayMarchMouse.x * 2.0 - 1.0, -(rayMarchMouse.y * 2.0 - 1.0), -0.5)
      ..normalize();

    for (int j = 0; j < pHeight; j++) {
      for (int i = 0; i < pWidth; i++) {
        double u = (i.toDouble() / pWidth.toDouble()) * 2.0 - 1.0;
        double v = (j.toDouble() / pHeight.toDouble()) * 2.0 - 1.0;
        v *= -1;
        vm.Vector3 ro = rayMarchCamPos.clone();
        vm.Vector3 rd = vm.Vector3(u * (pWidth / pHeight.toDouble()), v, 1.5)
          ..normalize(); // Aspect correct
        double t = 0;
        vm.Vector3 col = vm.Vector3.zero();
        for (int step = 0; step < 16; step++) {
          // Reduced steps further
          vm.Vector3 p = ro + rd * t;
          double d = _sceneSDF(p);
          if (d < 0.01) {
            vm.Vector3 normal = _calcNormal(p);
            double diffuse = math.max(0.0, normal.dot(lightDir));
            double specular = math
                .pow(math.max(0.0, _reflectVector(rd, normal).dot(lightDir)),
                    16.0)
                .toDouble(); // Reduced specular power
            col = (vm.Vector3(0.1, 0.4, 0.7) * diffuse + vm.Vector3.all(0.05)) +
                vm.Vector3.all(specular * 0.3); // Reduced specular intensity
            break;
          }
          t += math.max(d * 0.8, 0.02); // Slightly larger minimum step
          if (t > 15.0) break; // Reduced max distance
        }
        int R = (ui.clampDouble(col.r, 0, 1) * 255).toInt();
        int G = (ui.clampDouble(col.g, 0, 1) * 255).toInt();
        int B = (ui.clampDouble(col.b, 0, 1) * 255).toInt();
        int index = (j * pWidth + i) * 4;
        pixels[index + 0] = R;
        pixels[index + 1] = G;
        pixels[index + 2] = B;
        pixels[index + 3] = 255;
      }
    }

    // This callback is the crucial part to update the state with the new image.
    // It has to be done carefully to avoid setState during build.
    ui.decodeImageFromPixels(
      pixels,
      pWidth,
      pHeight,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        onRayMarchSnapshotUpdated(
            img); // This will trigger setState in _InteractiveViewerWidgetState via callback
      },
    );
  }

  double _sceneSDF(vm.Vector3 p) {
    vm.Vector3 sphereCenterOffset = vm.Vector3(
      math.sin(rayMarchMouse.x * 3.0).toDouble() * 0.5,
      math.cos(rayMarchMouse.y * 3.0).toDouble() * 0.5,
      0.0,
    );
    const double sphereRadius = 0.8;
    double sphereDist = (p - sphereCenterOffset).length - sphereRadius;

    vm.Vector3 boxPos = vm.Vector3(0.0, -1.2, 0.0);
    vm.Vector3 boxSize = vm.Vector3(1.5, 0.15, 1.5);
    vm.Vector3 pRelBox = p - boxPos;
    vm.Vector3 absPRelBox =
        vm.Vector3(pRelBox.x.abs(), pRelBox.y.abs(), pRelBox.z.abs());
    vm.Vector3 q = absPRelBox - boxSize;

    double boxDist = vm.Vector3(
          math.max(q.x, 0.0),
          math.max(q.y, 0.0),
          math.max(q.z, 0.0),
        ).length +
        math.min(math.max(q.x, math.max(q.y, q.z)), 0.0);
    return math.min(sphereDist, boxDist);
  }

  vm.Vector3 _calcNormal(vm.Vector3 p) {
    const double e =
        0.001; // Slightly larger epsilon for potentially faster/less precise normals
    return vm.Vector3(
      _sceneSDF(p + vm.Vector3(e, 0, 0)) - _sceneSDF(p - vm.Vector3(e, 0, 0)),
      _sceneSDF(p + vm.Vector3(0, e, 0)) - _sceneSDF(p - vm.Vector3(0, e, 0)),
      _sceneSDF(p + vm.Vector3(0, 0, e)) - _sceneSDF(p - vm.Vector3(0, 0, e)),
    ).normalized();
  }

  @override
  bool shouldRepaint(covariant SimulationPainter oldDelegate) {
    // Repaint if ray marching state changes, or if normal physics would repaint
    return rayMarchNeedsUpdate ||
        isRayMarchingEnabled != oldDelegate.isRayMarchingEnabled ||
        rayMarchSnapshot != oldDelegate.rayMarchSnapshot ||
        (!isRayMarchingEnabled &&
            true); // If not ray marching, always repaint (as before)
  }
}

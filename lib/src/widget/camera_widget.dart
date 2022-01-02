import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_filter_app/src/tools/camera_type.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraWidget extends StatefulWidget {
  final CustomCameraController controller;
  final CameraResolution cameraResolution;
  final CameraType defaultCameraType;

  CameraWidget(
      {Key? key,
      required this.controller,
      required this.defaultCameraType,
      this.cameraResolution = CameraResolution.high})
      : super(key: controller._key);

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
    with WidgetsBindingObserver {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  late int _selectedCameraIdx;
  bool isDisposed = false;

  CameraLensDirection get _lensDirection =>
      widget.defaultCameraType.toCameraLensDirection();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    availableCameras().then((availableCameras) {
      _cameras = availableCameras;
      if (_cameras.isNotEmpty) {
        final cameraId = _cameras.indexWhere((cameraDescription) =>
            cameraDescription.lensDirection == _lensDirection);
        setState(() {
          _selectedCameraIdx = cameraId;
        });
        permissionCheck();
      }
    });
  }

  @override
  void dispose() {
    _stopCamera();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (!isDisposed ||
        cameraController == null ||
        !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _controller = this._controller;
    if (isDisposed || _controller == null || !_controller.value.isInitialized) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Please allow permission to use the camera',
            style: TextStyle(color: Colors.white),
          ),
          TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text('Go to Settings')),
        ],
      ));
    }
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return Transform.scale(
      scale: scale,
      child: CameraPreview(_controller),
    );
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    await _stopCamera();
    ResolutionPreset resolutionPreset;
    switch (widget.cameraResolution) {
      case CameraResolution.max:
        resolutionPreset = ResolutionPreset.max;
        break;
      case CameraResolution.ultraHigh:
        resolutionPreset = ResolutionPreset.ultraHigh;
        break;
      case CameraResolution.veryHigh:
        resolutionPreset = ResolutionPreset.veryHigh;
        break;
      case CameraResolution.medium:
        resolutionPreset = ResolutionPreset.medium;
        break;
      case CameraResolution.low:
        resolutionPreset = ResolutionPreset.low;
        break;
      case CameraResolution.high:
      default:
        resolutionPreset = ResolutionPreset.high;
        break;
    }
    final _controller = CameraController(cameraDescription, resolutionPreset);
    this._controller = _controller;
    _controller.addListener(_cameraUpdate);
    await _controller.initialize();
    await _controller.lockCaptureOrientation();
    if (!widget.controller._completer.isCompleted) {
      widget.controller._completer.complete(true);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _cameraUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startCamera() => _initCameraController(
      _controller?.description ?? _cameras[_selectedCameraIdx]);

  Future<void> permissionCheck() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) _startCamera();
  }

  Future<void> _stopCamera() async {
    if (_controller == null) return;
    _controller?.removeListener(_cameraUpdate);
    await _controller?.dispose();
    isDisposed = true;
  }

  Future<void> _startRecordVideo() async {
    await _controller?.startVideoRecording();
  }

  Future<XFile?> _stopRecordVideo() async {
    final xFile = await _controller?.stopVideoRecording();
    return xFile;
  }

  void _addListener(VoidCallback listener) {
    _controller?.addListener(listener);
  }

  void _switchCamera() {
    _selectedCameraIdx =
        _selectedCameraIdx < _cameras.length - 1 ? _selectedCameraIdx + 1 : 0;
    final selectedCamera = _cameras[_selectedCameraIdx];
    _initCameraController(selectedCamera);
  }
}

class CustomCameraController {
  final _key = GlobalKey<_CameraWidgetState>();
  late final _completer = Completer();

  Size? get previewSize => _key.currentState?._controller?.value.previewSize;

  void startCamera() => _key.currentState?._startCamera();

  void stopCamera() => _key.currentState?._stopCamera();

  Future<void> startRecordVideo() async {
    await _key.currentState?._startRecordVideo();
  }

  Future<XFile?> stopRecordVideo() async {
    return _key.currentState?._stopRecordVideo();
  }

  void switchCamera() => _key.currentState?._switchCamera();

  Future<void> startImageStream(onLatestImageAvailable onAvailable) async {
    await _completer.future;
    return _key.currentState?._controller?.startImageStream(onAvailable);
  }

  Future<void> stopImageStream() async =>
      _key.currentState?._controller?.stopImageStream();

  void addListener(VoidCallback listener) =>
      _key.currentState?._addListener(listener);

  CameraValue? value() => _key.currentState?._controller?.value;
}

extension CameraTypes on CameraType {
  CameraLensDirection toCameraLensDirection() {
    switch (this) {
      case CameraType.front:
        return CameraLensDirection.front;
      case CameraType.external:
        return CameraLensDirection.external;
      case CameraType.back:
      default:
        return CameraLensDirection.back;
    }
  }
}

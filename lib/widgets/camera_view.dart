import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/src/face_detector.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
        required this.customPaint,
        required this.onImage,
        this.onCameraFeedReady,
        required this.faces,
        this.onDetectorViewModeChanged,
        this.onCameraLensDirectionChanged,
        this.captureImage,
        this.initialCameraLensDirection = CameraLensDirection.back})
      : super(key: key);

  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  List<Face> faces = [];
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final Function()? captureImage;
  final CameraLensDirection initialCameraLensDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  bool _changingCameraLens = false;
  List<String> imagesList = [
    'assets/goggles.png',
    'assets/Helment.png'
  ];
  String selectedFilterImage = '';
  GlobalKey _globalKey = GlobalKey();


  @override
  void initState() {
    super.initState();

    _initialize();
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          useMaterial3: true
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: Stack(
            children: [
              _liveFeedBody(),
              // ),
              if (widget.faces.isNotEmpty) _buildCapFilter(widget.faces.first),
            ],)),
    );
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: _changingCameraLens
                ? Center(
              child: const Text('Changing camera lens'),
            )
                : CameraPreview(
              _controller!,
              child: widget.customPaint,
            ),
          ),
          _filterImagesList(),
          _switchLiveCameraToggle(),
          _detectionViewModeToggle(),
        ],
      ),
    );
  }


  Widget _detectionViewModeToggle() => Positioned(
    bottom: 8,
    left: 8,
    child: SizedBox(
      height: 50.0,
      width: 50.0,
      child: FloatingActionButton(
        heroTag: Object(),
        onPressed: widget.onDetectorViewModeChanged,
        backgroundColor: Colors.black54,
        child: Icon(
          Icons.photo_library_outlined,
          size: 25,
          color: Colors.white,
        ),
      ),
    ),
  );


  Widget _switchLiveCameraToggle() => Positioned(
    bottom: 8,
    right: 8,
    child: SizedBox(
      height: 50.0,
      width: 50.0,
      child: FloatingActionButton(
        heroTag: Object(),
        onPressed: _switchLiveCamera,
        backgroundColor: Colors.black54,
        child: Icon(
          Platform.isIOS
              ? Icons.flip_camera_ios_outlined
              : Icons.flip_camera_android_outlined,
          size: 25,
          color: Colors.white,
        ),
      ),
    ),
  );

  Widget _filterImagesList() => Positioned(
    bottom: 50,
    child: Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 50),
      height: 140.0,
      width: 400.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagesList.length,
        itemBuilder: (BuildContext context, int index) {
        return InkWell(
          onTap: (){
            selectedFilterImage = imagesList[index];
            setState(() {

            });
          },
          child: Container(
            color: Colors.transparent,
            child: Image.asset(imagesList[index],height: 140,),
          ),
        );
      },),
    ),
  );


  Future _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        _currentZoomLevel = value;
        _minAvailableZoom = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        _maxAvailableZoom = value;
      });
      _currentExposureOffset = 0.0;
      _controller?.getMinExposureOffset().then((value) {
        _minAvailableExposureOffset = value;
      });
      _controller?.getMaxExposureOffset().then((value) {
        _maxAvailableExposureOffset = value;
      });
      _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
      _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }


  //method 2
  Widget _buildCapFilterr(Face face) {
    final landmarks = face.landmarks;
    final rightEyeLandmark = landmarks[FaceLandmarkType.rightEye];
    final leftEyeLandmark = landmarks[FaceLandmarkType.leftEye];
    final noseBaseLandmark = landmarks[FaceLandmarkType.noseBase];

    if (rightEyeLandmark != null && leftEyeLandmark != null && noseBaseLandmark != null && selectedFilterImage != null && selectedFilterImage.isNotEmpty) {
      final double midpointX = (rightEyeLandmark.position.x + leftEyeLandmark.position.x) / 2;
      final double midpointY = (rightEyeLandmark.position.y + leftEyeLandmark.position.y) / 2;
      final double noseBaseY = noseBaseLandmark.position.y.toDouble();
      final double noseToEyeDistance = noseBaseY - midpointY;
      final double initialTop = midpointY - 0.7 * noseToEyeDistance;

      double imageOffsetY = 0;
      if (selectedFilterImage == 'assets/goggles.png') {
        imageOffsetY = -0.4 * noseToEyeDistance;
      } else {
        imageOffsetY = -0.6 * noseToEyeDistance;
      }
      final double filterWidth = 1.2 * face.boundingBox.width;

      return RepaintBoundary(
        key: _globalKey,
        child: Positioned(
          left: midpointX - filterWidth / 2,
          top: initialTop + imageOffsetY,
          child: Transform.rotate(
            angle: face.headEulerAngleZ! * (pi / 180),
            child: Image.asset(
              selectedFilterImage,
              width: filterWidth,
              height: filterWidth,
            ),
          ),
        ),
      );

    } else {
      return Container();
    }
  }



//method 1
Widget _buildCapFilter(Face face) {
    final landmarks = face.landmarks;
    final noseBaseLandmarkright = landmarks[FaceLandmarkType.rightEye];
    final noseBaseLandmarkleft = landmarks[FaceLandmarkType.leftEye];
    final double filterWidth = 1.2 * face.boundingBox.width;
    if (noseBaseLandmarkright != null && selectedFilterImage!=null && selectedFilterImage.isNotEmpty) {
      return Positioned(
        left: noseBaseLandmarkright.position.x - 300,
        top: selectedFilterImage == 'assets/goggles.png' ? noseBaseLandmarkleft!.position.y - 260:noseBaseLandmarkleft!.position.y - 400,
        child:Transform.rotate(
          angle: face.headEulerAngleZ! * (pi / 180),
          child: Image.asset(
            selectedFilterImage,
            width: filterWidth/2,
            height: filterWidth/2,
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}

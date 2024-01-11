import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:camera/camera.dart';
import '../screens/video_player.dart';
import '../utils.dart';
import 'package:google_mlkit_face_detection/src/face_detector.dart';

class GalleryView extends StatefulWidget {
  GalleryView(
      {Key? key,
      required this.title,
      this.text,
      required this.onImage,
      required this.faces,
      required this.onDetectorViewModeChanged})
      : super(key: key);

  final String title;
  final String? text;
  List<Face> faces = [];
  final Function(InputImage inputImage) onImage;
  final Function()? onDetectorViewModeChanged;

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  File? _image;
  String? _path;
  ImagePicker? _imagePicker;
  List<String> imagesList = [
    'assets/goggles.png',
    'assets/Helment.png'
  ];
  String selectedFilterImage = '';
  String image = 'assets/goggles.png';

  @override
  void initState() {
    super.initState();
    print('widget.faces>>${widget.faces}');

    _imagePicker = ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          useMaterial3: true
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: widget.onDetectorViewModeChanged,
                  child: Icon(
                    Platform.isIOS ? Icons.camera_alt_outlined : Icons.camera,
                  ),
                ),
              ),
            ],
          ),
          body: _galleryBody()),
    );
  }
  Widget _filterImagesList() => Positioned(
    bottom:-40,
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

  Widget _galleryBody() {
    return ListView(shrinkWrap: true, children: [
      _image != null
          ? Stack(
            children: [
              SizedBox(
                height: 400,
                width: 400,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.file(_image!),
                    if (_image != null) _buildCapFilter(),
                  ],
                ),
              ),
              _filterImagesList(),
            ],
          )
          : Icon(
              Icons.image,
              size: 200,
            ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          onPressed: _getImageAsset,
          child: Text('From Assets'),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('From Gallery'),
          onPressed: () => _getImage(ImageSource.gallery),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('Take a picture'),
          onPressed: () => _getImage(ImageSource.camera),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('Play video'),
          onPressed: () {
            print('object');
            pickVideo(ImageSource.gallery);
          },
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
            child: Text('record video'),
            onPressed: () {
              pickVideo(ImageSource.camera);
              print('object');
            }),
      ),
      if (_image != null)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
              '${_path == null ? '' : 'Image path: $_path'}\n\n${widget.text ?? ''}'),
        ),
    ]);
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _path = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      _processFile(pickedFile.path);
    }
  }

  Future _getImageAsset() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final assets = manifestMap.keys
        .where((String key) => key.contains('images/'))
        .where((String key) =>
            key.contains('.jpg') ||
            key.contains('.jpeg') ||
            key.contains('.png') ||
            key.contains('.webp'))
        .toList();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select image',
                    style: TextStyle(fontSize: 20),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // for (final path in assets)
                          GestureDetector(
                            onTap: () async {
                              Navigator.of(context).pop();
                              _processFile(await getAssetPath(image));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(image),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel')),
                ],
              ),
            ),
          );
        });
  }

  Future _processFile(String path) async {
    setState(() {
      _image = File(path);
    });
    _path = path;
    final inputImage = InputImage.fromFilePath(path);
    widget.onImage(inputImage);
  }

  pickVideo(ImageSource videoSource) async {
    final videoFile = await ImagePicker().pickVideo(source: videoSource);
    if (videoFile != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VideoPlayerPage(
                  videoFile: File(videoFile.path), videoPath: videoFile.path)));
    }
  }

  Widget _buildCapFilter() {
    if (_image != null && selectedFilterImage!=null && selectedFilterImage.isNotEmpty) {
      return Positioned(
        left: 92,
        top: selectedFilterImage ==  'assets/goggles.png' ? 80 : 10,
        child: Image.asset(
          selectedFilterImage,
          height: selectedFilterImage == 'assets/goggles.png'?  160:200,
        ),
      );
    } else {
      return Container(); // Handle the case when 'noseBaseLandmark' is null
    }
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;

  FacePainter(this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    for (var face in faces) {
      final faceBounds = face.boundingBox;
      canvas.drawRect(faceBounds, Paint()..color = Colors.transparent);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

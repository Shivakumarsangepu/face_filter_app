import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_platform_interface/src/types/image_source.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionPage extends StatefulWidget {
  const FaceDetectionPage({Key? key}) : super(key: key);

  @override
  State<FaceDetectionPage> createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {

  bool textScanning = false;
  XFile? imageFile;
  String scannedText = "";
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;



  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }


  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Face Detection')),
      ),
      body: Center(
          child: SingleChildScrollView(
            child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white,
                                onPrimary: Colors.grey,
                                shadowColor: Colors.grey[400],
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                              ),
                              onPressed: () {
                                getImage(ImageSource.gallery);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 30,
                                    ),
                                    Text(
                                      "Gallery",
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey[600]),
                                    )
                                  ],
                                ),
                              ),
                            )),
                        Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white,
                                onPrimary: Colors.grey,
                                shadowColor: Colors.grey[400],
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                              ),
                              onPressed: ()  {
                                getImage(ImageSource.camera);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.camera_alt,
                                      size: 30,
                                    ),
                                    Text(
                                      "Camera",
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey[600]),
                                    )
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(imageFile!=null ? 'Picked Image':'Add an Image',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                    const SizedBox(
                      height: 20,
                    ),
                    if (textScanning) const CircularProgressIndicator(),
                    if (!textScanning && imageFile == null)
                      Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[300]!,
                        child: Center(child: Text('Please add an image')),
                      ),
                    if (imageFile != null)
                      Image.file(File(imageFile!.path)),
                    const SizedBox(
                      height: 20,
                    ),
                    Text('scannedText',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                    Container(
                      child: Text(
                        scannedText,
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  ],
                )),
          )),
    );
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      final faces = await _faceDetector.processImage(InputImage.fromFilePath(pickedImage!.path));
      print('faces>>${faces.toString()}');
      if (pickedImage != null) {
        textScanning = true;
        imageFile = pickedImage;
        setState(() {});
        getRecognisedText(pickedImage);
      }
    } catch (e) {
      textScanning = false;
      imageFile = null;
      scannedText = "Error occured while scanning";
      setState(() {});
    }
  }

  void getRecognisedText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textDetector = GoogleMlKit.vision.textRecognizer(script: TextRecognitionScript.latin);
    RecognizedText recognisedText = await textDetector.processImage(inputImage);
    await textDetector.close();
    scannedText = "";
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText = scannedText + line.text + "\n";
      }
    }
    textScanning = false;
    setState(() {});
  }
}

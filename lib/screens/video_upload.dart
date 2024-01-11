import 'package:face_filter_app/screens/video_player.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class UploadVideo extends StatefulWidget {
  const UploadVideo({Key? key}) : super(key: key);

  @override
  State<UploadVideo> createState() => _UploadVideoState();
}

class _UploadVideoState extends State<UploadVideo> {


  pickVideo(ImageSource videoSource) async {
    final videoFile = await ImagePicker().pickVideo(source: videoSource);
    if(videoFile!=null){
    Navigator.push(context, MaterialPageRoute(builder: (context) =>VideoPlayerPage(
          videoFile:File(videoFile.path),
          videoPath:videoFile.path

      )));
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('video player'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: (){
                  pickVideo(ImageSource.gallery);
                },
                  child: Text('Gallery')),
              const SizedBox(height: 50,),
              InkWell(
                onTap: (){
                  pickVideo(ImageSource.camera);
                },
                  child: Text('Camera')),

            ],
          ),
        ),
      ),
    );
  }
}

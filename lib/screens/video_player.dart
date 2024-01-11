import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';


class VideoPlayerPage extends StatefulWidget {
  final File? videoFile;
  final String? videoPath;
  const VideoPlayerPage({Key? key,required this.videoFile,required this.videoPath}) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {


  VideoPlayerController? playerController;

  @override
  void initState() {
    playerController = VideoPlayerController.file(widget.videoFile!);
    playerController!.initialize();
    playerController!.play();
    playerController!.setLooping(true);
    playerController!.setVolume(10);
    // TODO: implement initState
    super.initState();
  }



  @override
  void dispose() {
    playerController!.dispose();
    // TODO: implement dispose
    super.dispose();
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
          title: Row(
            children: [
              InkWell(
                onTap: (){
                  Navigator.pop(context);
                },
                  child: Icon(Icons.arrow_back)),
              SizedBox(width: 20,),
              Text('video player'),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height/1.6,
                child: VideoPlayer(playerController!),
              )

            ],
          ),
        ),
      ),
    );
  }


}


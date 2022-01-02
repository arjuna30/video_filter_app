import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_filter_app/src/const.dart';
import 'package:video_filter_app/src/tools/camera_type.dart';
import 'package:video_filter_app/src/widget/camera_widget.dart';

class VideoRecordPage extends StatefulWidget {
  final FlutterFFmpeg fFmpeg;
  static final route = ChildRoute(Modular.initialRoute,
      child: (context, args) => VideoRecordPage._(Modular.get()));

  const VideoRecordPage._(this.fFmpeg, {Key? key}) : super(key: key);

  @override
  _VideoRecordPageState createState() => _VideoRecordPageState();
}

class _VideoRecordPageState extends State<VideoRecordPage> {
  final CustomCameraController _controller = CustomCameraController();
  bool _isRecording = false;
  Color color = Colors.transparent;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.color),
            child: CameraWidget(
              controller: _controller,
              defaultCameraType: CameraType.back,
            ),
          ),
          Container(
            height: size.height * 0.22,
            decoration: const BoxDecoration(color: Colors.black38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _colorFilterButton(red),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: _colorFilterButton(green),
                    ),
                    _colorFilterButton(blue),
                  ],
                ),
                Center(
                  child: GestureDetector(
                    onTap:
                        (!_isRecording) ? _startRecordVideo : _stopRecordVideo,
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5)),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecordVideo() async {
    await _controller.startRecordVideo();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecordVideo() async {
    final xFile = await _controller.stopRecordVideo();
    if (xFile != null) {
      var tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/${xFile.name}';
      final hex = color.toString();
      final hexColor = hex.substring(10, hex.length - 1);
      _loadingDialog(context);
      await widget.fFmpeg.execute(
          '-i ${xFile.path} -f lavfi -i color=0x$hexColor:s=720x1280 -filter_complex blend=shortest=1:all_mode=overlay:all_opacity=0.7 $path');
      await GallerySaver.saveVideo(path);
      Modular.to.pop();
    }
    setState(() {
      _isRecording = false;
    });
  }

  Widget _colorFilterButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (color == this.color) {
            this.color = Colors.transparent;
            return;
          }
          this.color = color;
        });
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: (this.color == color)
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(style: BorderStyle.none),
        ),
      ),
    );
  }
}

_loadingDialog(BuildContext context) {
  return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Dialog(
            child: Container(
                height: 75, child: Center(child: Text('Saving ...'))));
      });
}

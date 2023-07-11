import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tflite/tflite.dart';
import 'dart:async';

class CameraWatcher with ChangeNotifier {
  bool ready = false;
  bool mounted = false;
  late CameraDescription _camera;
  late CameraController _controller;
  List<CameraDescription> _cameras = [];

  List<CameraDescription> get cameras => _cameras;
  CameraController get controller => _controller;
  CameraDescription get camera => _camera;

  Future<void> initCam() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      return;
    }
    ready = true;
    notifyListeners();
  }

  Future<void> mountCam() async {
    try {
      if (_cameras.isEmpty) {
        await initCam();
      }
      _camera = _cameras.first;
      _controller = CameraController(_camera, ResolutionPreset.medium);
      await _controller.initialize();
      mounted = true;
      notifyListeners();
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class OnEyes extends StatefulWidget {
  const OnEyes({Key? key}) : super(key: key);

  @override
  State<OnEyes> createState() => OnEyesState();
}

class OnEyesState extends State<OnEyes> {
  var listener = CameraWatcher();
  bool isDetecting = false;
  String recognizedObject = 'None';
  late CameraController _controller;
  int _imageCount = 0;

  @override
  void initState() {
    super.initState();
    loadModel();
    listener.initCam().then((_) {
      listener.mountCam().then((_) {
        _controller = listener.controller;
        _controller.startImageStream((image) {
          _imageCount++;
          if (!isDetecting && _imageCount % 60 == 0) {
            _imageCount = 0;
            isDetecting = true;
            runModelOnFrame(image);
          }
        });
      });
    });
  }

  Future<void> runModelOnFrame(CameraImage image) async {
    try {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        threshold: 0.1,
        asynch: true,
        numResults: 2,
      );

      print(recognitions);

      if (recognitions != null && recognitions.isNotEmpty) {
        recognitions.forEach((element) {
          print(element);
        });

        setState(() {
          recognizedObject = recognitions[0]['label'];
        });
      } else {
        print('No objects recognized');
      }

      isDetecting = false;
    } catch (e) {
      print('Error running model: $e');
    }
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/labels.txt",
      );
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  @override
  void dispose() async {
    await Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CameraWatcher>(
      create: (context) => listener,
      child: Consumer<CameraWatcher>(
        builder: (context, listener, _) {
          if (!listener.ready || !listener.mounted) {
            return const CircularProgressIndicator();
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Object Recognition'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Recognized Object: $recognizedObject',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

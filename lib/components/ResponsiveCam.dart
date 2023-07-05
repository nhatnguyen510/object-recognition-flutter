import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
// import 'package:camera_windows/camera_windows.dart';
import 'package:flutter/material.dart';

late CameraDescription _camera;
late CameraController _controller;
late Future<void> _initializeControllerFuture;

class CameraWatcher with ChangeNotifier {
  bool ready = false;
  bool mounted = false;
  late final _cameras;
  Future<void> initCam() async {
    _cameras = await availableCameras().whenComplete(() => notifyListeners());
    ready = true;
  }

  void mountCam() {
    try {
      _camera = _cameras.first;
      _controller = CameraController(_camera, ResolutionPreset.max);
      _initializeControllerFuture = _controller.initialize();
      mounted = true;

      // notifyListeners();
    } on CameraException catch (e) {
      initCam();
    }
  }
}

class OnEyes extends StatefulWidget {
  const OnEyes({super.key});

  @override
  State<OnEyes> createState() => OnEyesState();
}

class OnEyesState extends State<OnEyes> {
  var listener = CameraWatcher();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CameraWatcher(),
      child: Builder(builder: (context) {
        var listener = context.watch<CameraWatcher>();
        if (!listener.ready) {
          listener.initCam();
          return Padding(
            padding: EdgeInsets.all(10),
            child: Text('Finding camera...(Actually, we\'ve found none)'),
          );
        }
        if (!listener.mounted) listener.mountCam();
        return FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the Future is complete, display the preview.
              return CameraPreview(_controller);
            } else {
              // Otherwise, display a loading indicator.
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      }),
    );
  }
}

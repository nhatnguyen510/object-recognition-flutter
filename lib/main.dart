import 'package:flutter/material.dart';
import 'package:flutter_face_detection_app/components/user/ResponsiveCam.dart';
import 'package:flutter_face_detection_app/controllers/navigation.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_face_detection_app/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ListenableProvider<NavigationController>(
          create: (context) => NavigationController()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = '';

  @override
  Widget build(BuildContext context) {
    NavigationController navigationController =
        Provider.of<NavigationController>(context);

    return MaterialApp(
      title: _title,
      home: Navigator(
        pages: [
          const MaterialPage(
            key: ValueKey('MainPage'),
            child: MainPage(),
          ),
          if (navigationController.sreenName == "/object-recognition")
            const MaterialPage(
              key: ValueKey('ObjectRecognitionPage'),
              child: OnEyes(),
            ),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }

          context.read<NavigationController>().changeScreen("/");

          return true;
        },
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    NavigationController navigationController =
        Provider.of<NavigationController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Recognition App'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            navigationController.changeScreen("/object-recognition");
          },
          child: const Text('Start Object Recognition'),
        ),
      ),
    );
  }
}

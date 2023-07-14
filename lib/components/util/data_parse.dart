import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_face_detection_app/components/util/ClassifierModel.dart';

typedef ModelLabels = List<String>;

class Recognizer {
  final ModelLabels _Labels;
  final ClassifierModel _Model;

  Recognizer._({
    required ModelLabels labels,
    required ClassifierModel model,
  })  : _Labels = labels,
        _Model = model;

  static Future<Recognizer?> loadWith({
    required String labelsFile,
    required String modelFile,
  }) async {
    try {
      // TODO: LOAD LABELS and MODEL
      final labels = await _loadLabels(labelsFile);
      final model = await _loadModel(modelFile);

      return Recognizer._(labels: labels, model: model);
    } catch (e) {
      debugPrint('Initiation of recognizer failed.');
      debugPrint('$e');
    }
    return null;
  }

  static Future<ModelLabels> _loadLabels(String labelsFileName) async {
    final fileString = await rootBundle.loadString('$labelsFileName');
    final extracted = fileString.split('\n');
    var list = <String>[];
    for (var i = 0; i < extracted.length; i++) {
      var entry = extracted[i].trim();
      if (entry.length > 0) list.add(entry);
    }
    debugPrint('Labels: $list');
    return list;
  }

  static Future<ClassifierModel> _loadModel(String modelFileName) async {
    // #1
    final interpreter = await Interpreter.fromAsset(modelFileName);

    // #2
    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;

    debugPrint('Input shape: $inputShape');
    debugPrint('Output shape: $outputShape');

    // #3
    final inputType = interpreter.getInputTensor(0).type;
    final outputType = interpreter.getOutputTensor(0).type;

    debugPrint('Input type: $inputType');
    debugPrint('Output type: $outputType');

    return ClassifierModel(
      interpreter: interpreter,
      inputShape: inputShape,
      outputShape: outputShape,
      inputType: inputType,
      outputType: outputType,
    );
  }
}

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img_notWid;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_face_detection_app/components/util/converter.dart';
import 'package:flutter_face_detection_app/components/util/ClassifierCategory.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'dart:math';
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
      // LOAD LABELS and MODEL
      final labels = await _loadLabels(labelsFile);
      final model = await _loadModel(modelFile);

      return Recognizer._(labels: labels, model: model);
    } catch (e) {
      debugPrint('Initiation of recognizer failed.');
      debugPrint('$e');
    }
    return null;
  }

  ClassifierCategory predict(CameraImage image) {
    // TODO: _preProcessInput
    final inputImage = _preProcessImg(image);

    debugPrint(
      'Pre-processed image: ${inputImage.width}x${image.height}, '
      'size: ${inputImage.buffer.lengthInBytes} bytes',
    );

    // TODO: run TF Lite
    // #1
    final outputBuffer = TensorBuffer.createFixedSize(
      _Model.outputShape,
      _Model.outputType,
    );

// #2
    _Model.interpreter.run(inputImage.buffer, outputBuffer.buffer);
    debugPrint('OutputBuffer: ${outputBuffer.getDoubleList()}');

    // TODO: _postProcessOutput
    final resultCategories = _postProcessOutput(outputBuffer);
    final topResult = resultCategories.first;

    debugPrint('Top category: $topResult');

    return topResult;
    // return ClassifierCategory('Unknown', 0);
  }

  TensorImage _preProcessImg(CameraImage image) {
    try {
      final data = convertYUV420toImageColor(image);
      final processed = _preProcessInput(data);
      return processed;
    } catch (e) {
      debugPrint('Failed at preprocessing!!!');
      return TensorImage();
    }
    ;
  }

  static Future<ModelLabels> _loadLabels(String labelsFileName) async {
    final fileString = await rootBundle.loadString(labelsFileName);
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

  TensorImage _preProcessInput(img_notWid.Image image) {
    // #1
    final inputTensor = TensorImage(_Model.inputType);
    inputTensor.loadImage(image);

    // #2
    final minLength = min(inputTensor.height, inputTensor.width);
    final cropOp = ResizeWithCropOrPadOp(minLength, minLength);

    // #3
    final shapeLength = _Model.inputShape[1];
    final resizeOp = ResizeOp(shapeLength, shapeLength, ResizeMethod.BILINEAR);

    // #4
    final normalizeOp = NormalizeOp(127.5, 127.5);

    // #5
    final imageProcessor = ImageProcessorBuilder()
        .add(cropOp)
        .add(resizeOp)
        .add(normalizeOp)
        .build();

    imageProcessor.process(inputTensor);

    // #6
    return inputTensor;
  }

  List<ClassifierCategory> _postProcessOutput(TensorBuffer outputBuffer) {
    // #1
    final probabilityProcessor = TensorProcessorBuilder().build();

    probabilityProcessor.process(outputBuffer);

    // #2
    final labelledResult = TensorLabel.fromList(_Labels, outputBuffer);

    // #3
    final categoryList = <ClassifierCategory>[];
    labelledResult.getMapWithFloatValue().forEach((key, value) {
      final category = ClassifierCategory(key, value);
      categoryList.add(category);
      debugPrint('label: ${category.label}, score: ${category.score}');
    });

    // #4
    categoryList.sort((a, b) => (b.score > a.score ? 1 : -1));

    return categoryList;
  }
}

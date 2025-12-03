import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  Interpreter? _interpreter;

  // Input info
  List<int>? _inputShape;
  TensorType? _inputType;

  // Output info (Multiple outputs)
  List<List<int>> _outputShapes = [];
  List<TensorType> _outputTypes = [];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/ssd_mobilenet_v2_coco_quant_postprocess.tflite',
      );

      // 1. Configure Input (Assume 1 input for object detection)
      var inputTensor = _interpreter!.getInputTensor(0);
      _inputShape = inputTensor.shape;
      _inputType = inputTensor.type;

      // 2. Configure Outputs (Detect all)
      var outputCount = _interpreter!.getOutputTensors().length;
      _outputShapes.clear();
      _outputTypes.clear();

      for (int i = 0; i < outputCount; i++) {
        var t = _interpreter!.getOutputTensor(i);
        _outputShapes.add(t.shape);
        _outputTypes.add(t.type);
      }

      print('✅ Modelo cargado.');
      print('👉 Input: $_inputShape ($_inputType)');
      print('👉 Outputs detectados: $outputCount');
      for (int i = 0; i < outputCount; i++) {
        print('   Output $i: ${_outputShapes[i]} (${_outputTypes[i]})');
      }

    } catch (e) {
      print('❌ Error al cargar: $e');
      dispose();
    }
  }

  dynamic runInference(dynamic inputData) {
    if (_interpreter == null) return "Error: Intérprete no inicializado";

    try {
      print("DEBUG: Preparando buffers para ${_outputShapes.length} salidas...");
      
      // Map to store outputs: index -> buffer
      Map<int, Object> outputs = {};

      for (int i = 0; i < _outputShapes.length; i++) {
        var shape = _outputShapes[i];
        var type = _outputTypes[i];
        int size = shape.reduce((a, b) => a * b);

        if (type == TensorType.uint8) {
          outputs[i] = Uint8List(size).reshape(shape);
        } else {
          // Default to float32/double
          outputs[i] = List.filled(size, 0.0).reshape(shape);
        }
      }

      // Run inference using runForMultipleInputs
      // Inputs must be a list: [inputData]
      _interpreter!.runForMultipleInputs([inputData], outputs);

      print("DEBUG: Inferencia finalizada correctamente.");
      return outputs;

    } catch (e, stack) {
      print("Error en inferencia: $e");
      print(stack);
      return "Error: $e";
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _outputShapes.clear();
    _outputTypes.clear();
  }

  // Getters
  List<int> get inputShape => _inputShape ?? [];
  TensorType? get inputType => _inputType;
  
  // Compatibility getter (returns first output shape)
  List<int> get outputShape => _outputShapes.isNotEmpty ? _outputShapes[0] : [];
}
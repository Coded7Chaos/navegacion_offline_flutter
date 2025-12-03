import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/tflite_service.dart';
import '../utils/image_utils.dart';
import 'package:flutter/foundation.dart'; // for defaultTargetPlatform

class DetectorScreen extends StatefulWidget {
  const DetectorScreen({super.key});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  CameraController? _controller;
  final TfliteService _aiService = TfliteService();
  bool _isDetecting = false;
  
  // Results
  List<Map<String, dynamic>> _detections = [];
  
  // Meta info for coordinate scaling
  int _imageWidth = 1;
  int _imageHeight = 1;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _aiService.loadModel();
    
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print('No hay cámaras disponibles');
      return;
    }

    // Select back camera
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // 480p or 720p is enough for 300x300 model
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888, // Prefer BGRA on iOS
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      
      // Start streaming
      _controller!.startImageStream(_onCameraImage);
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _onCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    // Guardamos dimensiones para escalar cajas luego
    _imageWidth = image.width;
    _imageHeight = image.height;

    try {
      // 1. Process Image
      // Note: This is a simplified sync processing. 
      // In a real app, do this in an Isolate or use FFI.
      var inputMatrix = ImageUtils.processCameraImage(image, 300);
      
      if (inputMatrix.isEmpty) {
         _isDetecting = false;
         return;
      }
      
      // Add Batch Dim: [300, 300, 3] -> [1, 300, 300, 3]
      // TfliteService expects [inputData] in runForMultipleInputs, 
      // but let's match what we did in test: List<List<List<List<double>>>> or similar.
      // Actually our ImageUtils returns List<List<List<int>>>.
      // We wrap it in a list to make it a batch of 1.
      var input = [inputMatrix];

      // 2. Inference
      var results = _aiService.runInference(input);
      
      if (results is Map) {
         _processResults(results);
      }
      
    } catch (e) {
      print("Error processing frame: $e");
    } finally {
      _isDetecting = false;
    }
  }
  
  void _processResults(Map<dynamic, dynamic> outputs) {
     // Parse SSD MobileNet outputs
     // 0: Locations [1, N, 4]
     // 1: Classes [1, N]
     // 2: Scores [1, N]
     // 3: Count [1] (Optional sometimes)
     
     // Verify structure
     if (!outputs.containsKey(0) || !outputs.containsKey(1) || !outputs.containsKey(2)) return;
     
     var locations = outputs[0][0]; // List of [ymin, xmin, ymax, xmax]
     var classes = outputs[1][0];   // List of class indices
     var scores = outputs[2][0];    // List of scores
     
     List<Map<String, dynamic>> newDetections = [];
     
     // Iterate (usually 10 or 20 detections)
     for (int i = 0; i < scores.length; i++) {
       double score = scores[i];
       if (score > 0.5) { // Threshold 50%
          var rect = locations[i]; // [ymin, xmin, ymax, xmax]
          var classIndex = classes[i].toInt();
          
          newDetections.add({
            'rect': {
               'y': rect[0],
               'x': rect[1],
               'h': rect[2] - rect[0],
               'w': rect[3] - rect[1],
            },
            'label': _cocoLabels[classIndex] ?? "Unknown ($classIndex)",
            'confidence': score,
          });
       }
     }
     
     if (mounted) {
       setState(() {
         _detections = newDetections;
       });
     }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _aiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera Feed
          CameraPreview(_controller!),
          
          // Bounding Boxes
          _buildBoundingBoxes(),
          
          // Back Button
          Positioned(
            top: 40,
            left: 10,
            child: BackButton(color: Colors.white),
          ),
          
          // Info
          Positioned(
             bottom: 20,
             left: 20,
             child: Text(
               "Detecting: ${_detections.length} objects",
               style: TextStyle(color: Colors.white, backgroundColor: Colors.black54),
             ),
          )
        ],
      ),
    );
  }
  
  Widget _buildBoundingBoxes() {
     return LayoutBuilder(
       builder: (context, constraints) {
          // Calculate scale factors
          // CameraPreview usually fills width or height (Cover).
          // Simplified assumption: Camera aspect ratio matches screen or is fitted.
          // We need to map normalized [0,1] coords to screen [w, h].
          
          // NOTE: Coordinates from TFLite are usually [ymin, xmin, ymax, xmax] based on the input image.
          // If the input was rotated (portrait), we might need to swap axes.
          
          double w = constraints.maxWidth;
          double h = constraints.maxHeight;
          
          return Stack(
            children: _detections.map((d) {
               var rect = d['rect'];
               
               // Simple mapping (might be mirrored/rotated depending on device)
               // For Portrait Mode usually: x is x, y is y.
               double left = rect['x'] * w;
               double top = rect['y'] * h;
               double width = rect['w'] * w;
               double height = rect['h'] * h;
               
               return Positioned(
                 left: left,
                 top: top,
                 width: width,
                 height: height,
                 child: Container(
                   decoration: BoxDecoration(
                     border: Border.all(color: Colors.red, width: 3),
                   ),
                   child: Text(
                     "${d['label']} ${(d['confidence']*100).toStringAsFixed(0)}%",
                     style: TextStyle(
                       color: Colors.white, 
                       background: Paint()..color = Colors.red,
                       fontSize: 12,
                     ),
                   ),
                 ),
               );
            }).toList(),
          );
       },
     );
  }
  
  // Short COCO list
  final Map<int, String> _cocoLabels = {
    0: 'background', 1: 'person', 2: 'bicycle', 3: 'car', 4: 'motorcycle',
    5: 'airplane', 6: 'bus', 7: 'train', 8: 'truck', 9: 'boat',
    10: 'traffic light', 11: 'fire hydrant', 13: 'stop sign', 14: 'parking meter',
    15: 'bench', 16: 'bird', 17: 'cat', 18: 'dog', 19: 'horse',
    20: 'sheep', 21: 'cow', 22: 'elephant', 23: 'bear', 24: 'zebra',
    25: 'giraffe', 27: 'backpack', 28: 'umbrella', 31: 'handbag',
    32: 'tie', 33: 'suitcase', 34: 'frisbee', 35: 'skis', 36: 'snowboard',
    37: 'sports ball', 38: 'kite', 39: 'baseball bat', 40: 'baseball glove',
    41: 'skateboard', 42: 'surfboard', 43: 'tennis racket', 44: 'bottle',
    46: 'wine glass', 47: 'cup', 48: 'fork', 49: 'knife', 50: 'spoon',
    51: 'bowl', 52: 'banana', 53: 'apple', 54: 'sandwich', 55: 'orange',
    56: 'broccoli', 57: 'carrot', 58: 'hot dog', 59: 'pizza', 60: 'donut',
    61: 'cake', 62: 'chair', 63: 'couch', 64: 'potted plant', 65: 'bed',
    67: 'dining table', 70: 'toilet', 72: 'tv', 73: 'laptop', 74: 'mouse',
    75: 'remote', 76: 'keyboard', 77: 'cell phone', 78: 'microwave',
    79: 'oven', 80: 'toaster', 81: 'sink', 82: 'refrigerator', 84: 'book',
    85: 'clock', 86: 'vase', 87: 'scissors', 88: 'teddy bear',
    89: 'hair drier', 90: 'toothbrush'
  };
}

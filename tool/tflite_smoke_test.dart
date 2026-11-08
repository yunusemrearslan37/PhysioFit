import 'dart:io';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

Future<void> main() async {
  final modelFile = File('assets/models/best_integer_quant.tflite');
  if (!modelFile.existsSync()) {
    stderr.writeln('Model file not found: ${modelFile.path}');
    exitCode = 1;
    return;
  }

  final interpreter = Interpreter.fromFile(modelFile, options: InterpreterOptions()..threads = 2);
  interpreter.allocateTensors();

  final in0 = interpreter.getInputTensor(0);
  final out0 = interpreter.getOutputTensor(0);

  stdout.writeln('INPUT 0: shape=${in0.shape} type=${in0.type}');
  stdout.writeln('OUTPUT 0: shape=${out0.shape} type=${out0.type}');

  // Build dummy input matching float32[1,640,640,3]
  final input = Float32List(1 * 640 * 640 * 3);
  // output float32[1,17,8400]
  final output = Float32List(17 * 8400);

  try {
    interpreter.run(input, output);
    stdout.writeln('OK: ran inference. first output values: ${output.take(5).toList()}');
  } catch (e, st) {
    stderr.writeln('ERROR: $e');
    stderr.writeln(st);
    exitCode = 2;
  } finally {
    interpreter.close();
  }
}



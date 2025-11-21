import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/vertex_ai_service.dart';
import '../services/firestore_service.dart';

class GenerationProvider with ChangeNotifier {
  final VertexAIService _vertexAIService = VertexAIService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isGenerating = false;
  Uint8List? _generatedImage;
  String? _error;

  bool get isGenerating => _isGenerating;
  Uint8List? get generatedImage => _generatedImage;
  String? get error => _error;

  Future<void> generateImage(
    String prompt,
    String aspectRatio,
    String uid,
  ) async {
    _isGenerating = true;
    _error = null;
    _generatedImage = null;
    notifyListeners();

    try {
      // Check credits first
      final hasCredit = await _firestoreService.deductCredit(uid);
      if (!hasCredit) {
        throw 'Insufficient credits. Watch an ad to earn more!';
      }

      final imageBytes = await _vertexAIService.generateImage(
        prompt,
        aspectRatio,
      );
      if (imageBytes != null) {
        _generatedImage = imageBytes;
        // Increment generated count
        await _firestoreService.incrementGeneratedCount(uid);
      } else {
        throw 'Failed to generate image.';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clearImage() {
    _generatedImage = null;
    _error = null;
    notifyListeners();
  }

  void setGeneratedImage(Uint8List image) {
    _generatedImage = image;
    notifyListeners();
  }
}

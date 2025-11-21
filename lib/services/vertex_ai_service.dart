import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class VertexAIService {
  static const _scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  Future<AutoRefreshingAuthClient> _getAuthClient() async {
    final jsonString = await rootBundle.loadString(
      'assets/service_account.json',
    );
    final credentials = ServiceAccountCredentials.fromJson(jsonString);
    return clientViaServiceAccount(credentials, _scopes);
  }

  Future<Uint8List?> generateImage(String prompt, String aspectRatio) async {
    final apiKey = dotenv.env['HUGGING_FACE_API_KEY'] ?? '';
    final client = await _getAuthClient();

    // Load Project ID
    final jsonString = await rootBundle.loadString(
      'assets/service_account.json',
    );
    final jsonMap = json.decode(jsonString);

    // Agar JSON se ID na mile to yahan manual likh sakte hain
    final projectId = jsonMap['project_id'];

    final location = 'us-central1';

    // CHANGE: Using Imagen 2 (Stable Model)
    // Yeh model empty response nahi deta agar prompt safe ho
    final endpoint =
        'https://$location-aiplatform.googleapis.com/v1/projects/$projectId/locations/$location/publishers/google/models/imagegeneration@006:predict';

    final body = {
      "instances": [
        {"prompt": prompt},
      ],
      "parameters": {
        "sampleCount": 1,
        "aspectRatio": aspectRatio, // e.g., "16:9", "1:1"
      },
    };

    try {
      print("Sending Request to Vertex AI (Imagen 2)...");
      final response = await client.post(
        Uri.parse(endpoint),
        body: json.encode(body),
      );

      print("Response Status: ${response.statusCode}");
      // Debugging ke liye body print kar rahe hain
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List?;

        if (predictions != null && predictions.isNotEmpty) {
          // Imagen 2 hamesha 'bytesBase64Encoded' bhejta hai
          final bytesBase64 =
              predictions[0]['bytesBase64Encoded'] ??
              predictions[0]['bytesBase64String'];

          if (bytesBase64 != null) {
            return base64Decode(bytesBase64);
          } else {
            throw 'Image data missing in response.';
          }
        } else {
          // Agar predictions khaali hon
          throw 'No image returned. Your prompt might be blocked by Safety Filters.';
        }
      } else {
        throw 'Failed to generate: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      print("ERROR in Vertex AI: $e");
      throw e.toString();
    } finally {
      client.close();
    }
    return null;
  }
}

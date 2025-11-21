import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  Future<String?> enhancePrompt(String currentPrompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    try {
      print("Asking Magic AI to enhance prompt...");

      // Hum Pollinations AI (Open Source) use kar rahe hain jo free text generation deta hai
      // Yeh URL automatic prompt ko rewrite karke wapis dega
      final String query =
          "Rewrite this as a detailed, creative AI image generation prompt (under 50 words). Only return the prompt, no other text. \n\nInput: $currentPrompt";

      // URL encode karna zaroori hai taake spaces handle ho jayen
      final Uri url = Uri.parse(
        'https://text.pollinations.ai/${Uri.encodeComponent(query)}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Pollinations direct text return karta hai
        final String result = response.body.trim();
        print("Magic Result: $result");
        return result;
      } else {
        print('Magic AI Error: ${response.statusCode}');
        throw 'Failed to enhance. Try again.';
      }
    } catch (e) {
      print("ERROR in Magic Service: $e");
      // Agar fail ho, to purana prompt hi wapis bhej do taake app na ruke
      return currentPrompt;
    }
  }
}

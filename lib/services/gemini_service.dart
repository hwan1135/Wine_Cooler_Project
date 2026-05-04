import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/wine.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<Wine?> processWineInput(String input) async {
    final prompt = '''
    Analyze this wine input: "$input". 
    Provide the details in a valid JSON format with keys: "title", "vintage", "country", and "price". 
    If a value is unknown, use "N/A" for strings and 0.0 for numbers.
    Return ONLY the JSON object.
    ''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text;

    if (text != null) {
      final Map<String, dynamic> decoded = jsonDecode(_extractJson(text));
      return Wine.fromJson(decoded);
    }
    return null;
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    return (start != -1 && end != -1) ? text.substring(start, end + 1) : text;
  }
}

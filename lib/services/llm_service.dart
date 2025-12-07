import 'package:google_generative_ai/google_generative_ai.dart';

class LLMService {
  late GenerativeModel _model;
  static const String _apiKey = 'AIzaSyBwbpG7j5WoySrb901P4oSni25Nmct-hPA';
  
  LLMService({String? apiKey}) {
    _model = GenerativeModel(
      model: 'Gemini 2.5 Flash',
      apiKey: apiKey ?? _apiKey,
    );
  }

  // ========== AGENT 1: Educational Chatbot ==========
  // Specialized for helping students with educational questions
  Future<String> chatWithEducationalAI(String userMessage) async {
    final prompt = '''
You are an expert educational tutor helping a student with their studies. Your role is to:
- Explain concepts clearly and simply
- Break down complex topics into easy-to-understand steps
- Provide examples and analogies
- Encourage learning and critical thinking
- Stay focused on educational topics only

Student's question: "$userMessage"

Provide a helpful, educational response (max 3-4 sentences):
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? 'I apologize, I could not generate a response. Please try again.';
  }

  // ========== AGENT 2: Content Classifier ==========
  // Determines if app content is educational or non-educational
  Future<Map<String, dynamic>> classifyContent({
    required String appName,
    String? screenText,
    String? windowTitle,
  }) async {
    final prompt = '''
You are a content classification AI. Analyze if the following app usage is EDUCATIONAL or NON-EDUCATIONAL.

App Name: $appName
${windowTitle != null ? 'Window Title: $windowTitle' : ''}
${screenText != null ? 'Screen Content: ${screenText.substring(0, screenText.length > 200 ? 200 : screenText.length)}' : ''}

Classify as:
- EDUCATIONAL: Learning apps, study tools, educational videos, homework help, research
- NON-EDUCATIONAL: Social media, gaming, entertainment, shopping, general browsing

Respond in JSON format:
{
  "classification": "EDUCATIONAL" or "NON-EDUCATIONAL",
  "confidence": 0.0 to 1.0,
  "reason": "brief explanation"
}

Response:
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final text = response.text ?? '{"classification":"UNKNOWN","confidence":0.0,"reason":"Error"}';
    
    try {
      // Extract JSON from response
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = text.substring(jsonStart, jsonEnd);
        // Parse manually to avoid import issues
        return _parseClassificationResponse(jsonStr);
      }
    } catch (e) {
      print('Error parsing classification: $e');
    }
    
    return {
      'classification': 'UNKNOWN',
      'confidence': 0.0,
      'reason': 'Could not classify',
    };
  }

  Map<String, dynamic> _parseClassificationResponse(String jsonStr) {
    // Simple JSON parsing for our specific format
    final classMatch = RegExp(r'"classification"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
    final confMatch = RegExp(r'"confidence"\s*:\s*([0-9.]+)').firstMatch(jsonStr);
    final reasonMatch = RegExp(r'"reason"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
    
    return {
      'classification': classMatch?.group(1) ?? 'UNKNOWN',
      'confidence': double.tryParse(confMatch?.group(1) ?? '0.0') ?? 0.0,
      'reason': reasonMatch?.group(1) ?? 'No reason provided',
    };
  }

  // ========== AGENT 3: Voice Intent Parser ==========
  // Parses voice commands for blind mode navigation
  Future<String?> parseVoiceCommandForBlindMode(String voiceInput) async {
    final prompt = '''
You are a voice navigation assistant for a blind student using an educational app.

Available pages:
- "home" - Main dashboard
- "assignments" - View and submit assignments  
- "ai_assist" - Get help with studies
- "settings" - App settings
- "logout" - Sign out

User said: "$voiceInput"

Determine which page the user wants to navigate to. Consider variations like:
- "go to assignments" → assignments
- "show me homework" → assignments
- "help me study" → ai_assist
- "I need help" → ai_assist
- "go back home" → home
- "sign out" → logout

Respond with ONLY the page name from the list above, or "unknown" if unclear.

Response (one word only):
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final result = response.text?.trim().toLowerCase() ?? 'unknown';
    
    final validPages = ['home', 'assignments', 'ai_assist', 'settings', 'logout'];
    if (validPages.contains(result)) {
      return result;
    }
    
    return null; // Unknown command
  }

  // Legacy method for backward compatibility
  Future<String> chatWithAI(String userMessage) async {
    return await chatWithEducationalAI(userMessage);
  }

  // Legacy method for backward compatibility  
  Future<String?> parseVoiceCommand(String voiceInput) async {
    return await parseVoiceCommandForBlindMode(voiceInput);
  }

  // Helper to check if content is educational
  Future<bool> isEducational(String appName, {String? screenText}) async {
    final result = await classifyContent(
      appName: appName,
      screenText: screenText,
    );
    return result['classification'] == 'EDUCATIONAL';
  }
}

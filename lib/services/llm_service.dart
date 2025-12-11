import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class LLMService {
  late GenerativeModel _model;
  static const String _apiKey = 'AIzaSyACZkZmB31uVpHNa1hPJ9JxAWwZ5JcEssE';

  LLMService({String? apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey ?? _apiKey,
    );
  }

  // ========== AGENT 1: Educational Chatbot ==========
  // Specialized for helping students with educational questions
  // ========== AGENT 1: Educational Chatbot ==========
  // Specialized for helping students with educational questions

  ChatSession createEducationalChatSession() {
    return _model.startChat(
      history: [
        Content('user', [
          TextPart('''
You are an expert educational tutor for students of all levels.

Your role:
- Explain concepts clearly and simply.
- Break down complex topics into easy steps.
- Use analogies, examples, and real-life explanations.
- Use Markdown formatting for clarity:
  * Bold text for key ideas
  * Bullet points for lists
  * Code blocks for code examples
- Stay fully focused on the academic question only.
- Encourage learning and critical thinking.
- Avoid unrelated content.

When answering:
- Start with a short and simple explanation.
- Then give a more detailed explanation if needed.
- Give examples to make ideas easy to understand.
- If the user asks the same question again:
  * Simplify the answer more than before
  * Use even simpler language
  * Remove technical words
  * Use a short analogy or example
- Never say “as I said before.” Just simplify kindly.

Communication style:
- Friendly, patient, and supportive.
- Never judge or discourage the student.
- If the student is confused:
  * ask a small clarifying question
  * guide step-by-step
'''),
        ]),
        Content('model', [
          TextPart('Understood. I am ready to help you with your studies.'),
        ]),
      ],
    );
  }

  Future<String> chatWithEducationalAI(String userMessage) async {
    // Stateless legacy method (kept for fallback)
    final prompt = '''
You are an expert educational tutor.
Student's question: "$userMessage"
Provide a helpful, educational response (max 3-4 sentences):
''';
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? 'Error generating response.';
  }

  // ========== AGENT 2: Content Classifier ==========
  // Classifies whether the user's current app usage supports learning.
  // Designed for a student-learning environment.
  Future<Map<String, dynamic>> classifyContent({
    required String appName,
    String? screenText,
    String? windowTitle,
  }) async {
    final prompt = '''
You are an educational content classifier AI.
Your task is to analyze if the app usage is:
**EDUCATIONAL** (helps student learning) or **NON-EDUCATIONAL** (does not support learning).

Context:
App Name: $appName
${windowTitle != null ? 'Window Title: $windowTitle' : ''}
${screenText != null ? 'Screen Content: ${screenText.substring(0, screenText.length > 200 ? 200 : screenText.length)}' : ''}

Definition:
EDUCATIONAL means:
- Study apps (e.g., Physics, Math, Coding)
- Learning platforms (e.g., Courses, Tutorials)
- Homework help and assignments
- Research or reading educational material
- Productivity tools used for learning (notes, flashcards)

NON-EDUCATIONAL means:
- Social media scrolling (Instagram, TikTok, etc.)
- Gaming and entertainment
- Shopping or product browsing
- Movie/music streaming
- Personal chat not related to study

If the content is mixed:
- Classify based on **majority intent**
- Be strict: if unsure, choose NON-EDUCATIONAL

Output Format (JSON only):
{
  "classification": "EDUCATIONAL" or "NON-EDUCATIONAL",
  "confidence": 0.0 to 1.0,
  "reason": "short explanation (max 20 words)"
}

Do not add extra text. Respond only with JSON.
Response:
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final text =
        response.text ??
        '{"classification":"UNKNOWN","confidence":0.0,"reason":"Error"}';

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
      debugPrint('Error parsing classification: $e');
    }

    return {
      'classification': 'UNKNOWN',
      'confidence': 0.0,
      'reason': 'Could not classify',
    };
  }

  Map<String, dynamic> _parseClassificationResponse(String jsonStr) {
    // Simple JSON parsing for our specific format
    final classMatch = RegExp(
      r'"classification"\s*:\s*"([^"]+)"',
    ).firstMatch(jsonStr);
    final confMatch = RegExp(
      r'"confidence"\s*:\s*([0-9.]+)',
    ).firstMatch(jsonStr);
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
You are a voice intent parser for a BLIND STUDENT using an educational app.

Your job:
- Understand the student's voice command.
- Decide which ONE app page they want.

Available pages (return EXACTLY one of these keys):
- "home"       → Main dashboard or main screen
- "assignments" → Homework, tasks, submissions, classwork
- "ai_assist"  → Study help, doubt solving, "AI", "assistant"
- "settings"   → Change options, volume, voice, preferences
- "logout"     → Sign out, exit account

Student said: "$voiceInput"

Mapping examples (not exhaustive):
- "go to assignments", "open homework", "show my tasks"
    → assignments
- "show me homework", "check my submissions"
    → assignments
- "help me study", "I need help with my subject", "open AI", "ask the assistant"
    → ai_assist
- "go back home", "go to main screen", "open dashboard"
    → home
- "change settings", "change voice speed", "open options"
    → settings
- "sign out", "log me out", "exit my account"
    → logout

Rules:
- Ignore polite words like "please", "can you", "hey".
- Focus on the main intent of the sentence.
- If the command clearly matches one page → return that page key.
- If the command is unclear, off-topic, or not about navigation → return "unknown".

Very important:
- Respond with ONLY ONE WORD:
  - "home"
  - "assignments"
  - "ai_assist"
  - "settings"
  - "logout"
  - "unknown"
- Do NOT add any extra text, symbols, or explanation.

Response:
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    final result = response.text?.trim().toLowerCase() ?? 'unknown';

    final validPages = [
      'home',
      'assignments',
      'ai_assist',
      'settings',
      'logout',
      'unknown', // Include unknown in valid check, though it returns null below if not in list logic? Wait, user code returns result if in validPages.
    ];
    if (validPages.contains(result)) {
      return result;
    }

    return null; // Unknown or invalid command
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

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Shared Firebase AI Logic setup (Gemini Developer API, free tier on the
/// Spark plan). See docs/FIREBASE_SETUP.md for the console and App Check steps.
class FirebaseAiSetup {
  /// Light model: short checks need little reasoning and the free tier
  /// allows more requests per day than Flash. Check limits in AI Studio.
  static const model = 'gemini-3.5-flash-lite';

  /// Debug builds only; register it under App Check > Manage debug tokens.
  /// Release builds use Play Integrity. Revoke it in the console if leaked.
  static const _debugToken = '756BFABF-BD4F-4621-8C58-B3E3A63571C2';
  static Future<void>? _setup;

  static Future<void> _prepare() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider(debugToken: _debugToken)
            : const AndroidPlayIntegrityProvider());
  }

  /// A JSON-answering model with the given instructions and schema.
  static Future<GenerativeModel> jsonModel(
      String instructions, Schema schema) async {
    try {
      await (_setup ??= _prepare());
    } catch (_) {
      _setup = null;
      rethrow;
    }
    return FirebaseAI.googleAI().generativeModel(
        model: model,
        systemInstruction: Content.system(instructions),
        generationConfig: GenerationConfig(
            temperature: 0.2,
            responseMimeType: 'application/json',
            responseSchema: schema));
  }
}

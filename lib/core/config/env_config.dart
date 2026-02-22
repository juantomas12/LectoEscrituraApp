import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get openAiApiKey => (dotenv.env['OPENAI_API_KEY'] ?? '').trim();

  static String get openAiModel =>
      (dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini').trim();
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  static AiService? _instance;
  static AiService get instance => _instance ??= AiService._();
  AiService._();

  // Provider에서 new AiService() 호출을 위한 팩토리
  factory AiService() => instance;

  static const String _dartDefineApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Gemini API 키 - .env 파일 우선, 없으면 --dart-define 사용
  String get _apiKey {
    final envKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (envKey.isNotEmpty) return envKey;
    return _dartDefineApiKey.trim();
  }

  static const String _modelName = 'gemini-2.5-flash-lite';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent';

  Future<List<String>> generateDiscussionQuestions({
    required String bookCode,
    required int chapter,
    required String bookName,
    required List<String> verses,
    required String myReflection,
    required String partnerReflection,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == '여기에_실제_API_키를_입력하세요') {
      debugPrint('Gemini API skipped: GEMINI_API_KEY is empty or placeholder.');
      return _getDefaultQuestions();
    }

    final verseText = verses.take(10).join('\n');
    final prompt = '''
당신은 크리스천 커플의 성경 말씀 나눔을 돕는 AI 도우미입니다.

오늘 읽은 성경 말씀: $bookName $chapter장
주요 구절:
$verseText

나의 소감: $myReflection

파트너의 소감: $partnerReflection

위의 말씀과 두 사람의 소감을 바탕으로, 커플이 함께 깊이 있는 대화를 나눌 수 있는 질문 3가지를 생성해주세요.

조건:
- 질문은 성경 말씀의 내용을 기반으로 해야 합니다.
- 두 사람의 소감 차이나 공통점을 발견할 수 있는 질문을 포함하세요.
- 커플 관계에 적용할 수 있는 질문을 포함하세요.
- 함께 실천하거나 기억할 수 있는 질문을 포함하세요.
- 따뜻하고 친근한 어조로 작성해주세요.
- 각 질문은 한 문장으로 작성하고, 반드시 80자 이내로 작성해주세요.
- 질문 앞에 번호, 설명, 분류명을 붙이지 마세요.

응답 형식 (반드시 JSON):
{
  "questions": [
    "80자 이내 질문",
    "80자 이내 질문",
    "80자 이내 질문"
  ]
}
''';

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 512,
                'topP': 0.95,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // JSON 파싱
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          final jsonData = json.decode(jsonMatch.group(0)!);
          final questions = List<String>.from(jsonData['questions'] ?? []);
          if (questions.length >= 3) return questions.take(3).toList();
          debugPrint(
            'Gemini API returned JSON, but questions length was ${questions.length}.',
          );
        } else {
          debugPrint('Gemini API response did not contain a JSON object.');
        }
      } else {
        debugPrint(
          'Gemini API failed: status=${response.statusCode}, body=${response.body}',
        );
      }
    } catch (e, stackTrace) {
      // API 오류 시 기본 질문 반환
      debugPrint('Gemini API error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    return _getDefaultQuestions();
  }

  bool isDefaultQuestions(List<String> questions) {
    final defaults = _getDefaultQuestions();
    if (questions.length != defaults.length) return false;
    for (var i = 0; i < defaults.length; i++) {
      if (questions[i] != defaults[i]) return false;
    }
    return true;
  }

  List<String> _getDefaultQuestions() {
    return [
      '오늘 말씀에서 하나님의 어떤 마음을 느꼈나요? 서로의 느낌을 나눠보세요.',
      '이 말씀의 가르침을 우리 관계에서 실천한다면 어떤 모습일까요?',
      '이번 주 이 말씀을 바탕으로 함께 해볼 수 있는 구체적인 한 가지를 정해볼까요?',
    ];
  }
}

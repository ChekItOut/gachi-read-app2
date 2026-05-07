import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static AiService? _instance;
  static AiService get instance => _instance ??= AiService._();
  AiService._();

  // 기본 생성자 (provider에서 new AiService() 호출을 위해)
  factory AiService() => instance;

  // Gemini API 키 - 환경변수 또는 앱 설정에서 가져옴
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<List<String>> generateDiscussionQuestions({
    required String bookCode,
    required int chapter,
    required String bookName,
    required List<String> verses,
    required String myReflection,
    required String partnerReflection,
  }) async {
    if (_apiKey.isEmpty) {
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
- 질문은 성경 말씀의 내용을 기반으로 해야 합니다
- 두 사람의 소감 차이나 공통점을 발견할 수 있는 질문을 포함하세요
- 실생활에 적용할 수 있는 질문을 포함하세요
- 따뜻하고 친근한 어조로 작성해주세요
- 각 질문은 한 문장으로 간결하게 작성해주세요

응답 형식 (JSON):
{
  "questions": [
    "질문1",
    "질문2",
    "질문3"
  ]
}
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
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
            'maxOutputTokens': 1024,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

        // JSON 파싱
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          final jsonData = json.decode(jsonMatch.group(0)!);
          final questions = List<String>.from(jsonData['questions'] ?? []);
          if (questions.isNotEmpty) return questions;
        }
      }
    } catch (e) {
      // API 오류 시 기본 질문 반환
    }

    return _getDefaultQuestions();
  }

  List<String> _getDefaultQuestions() {
    return [
      '오늘 말씀 중 가장 마음에 와닿은 구절은 무엇인가요? 그 이유도 함께 나눠보세요.',
      '이 말씀을 우리 관계에 어떻게 적용할 수 있을까요?',
      '오늘 말씀을 통해 하나님께서 우리에게 무엇을 말씀하고 계신다고 생각하나요?',
    ];
  }
}

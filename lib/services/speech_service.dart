import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isInitialized = false;
  
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speech.initialize(
      onError: (error) => print('语音识别错误: $error'),
      onStatus: (status) => print('语音识别状态: $status'),
    );
    return _isInitialized;
  }
  
  static Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        }
      },
      localeId: 'zh_CN',
      listenMode: ListenMode.confirmation,
      partialResults: true,
    );
  }
  
  static Future<void> stopListening() async {
    await _speech.stop();
  }
  
  static bool get isListening => _speech.isListening;
  
  static Future<bool> get isAvailable async {
    if (!_isInitialized) await initialize();
    return _isInitialized && _speech.isAvailable;
  }
}

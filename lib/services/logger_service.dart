import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  late Logger _logger;
  late File _logFile;
  final List<LogEntry> _logHistory = [];
  final int maxLogEntries = 500;

  LoggerService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 100,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
    _initLogFile();
  }

  factory LoggerService() {
    return _instance;
  }

  Future<void> _initLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp =
          DateTime.now().toString().replaceAll(':', '-').split('.')[0];
      _logFile = File('${directory.path}/app_logs_$timestamp.txt');

      // Create file if it doesn't exist
      if (!await _logFile.exists()) {
        await _logFile.create(recursive: true);
      }
    } catch (e) {
      _logger.e('Failed to initialize log file: $e');
    }
  }

  Future<void> _writeToFile(String logMessage) async {
    try {
      final timestamp =
          DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final message = '[$timestamp] $logMessage\n';
      await _logFile.writeAsString(
        message,
        mode: FileMode.append,
      );
    } catch (e) {
      _logger.e('Failed to write to log file: $e');
    }
  }

  void _addToHistory(LogEntry entry) {
    _logHistory.add(entry);
    if (_logHistory.length > maxLogEntries) {
      _logHistory.removeAt(0);
    }
  }

  // Logging Methods
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message);
    _writeToFile('[DEBUG] $message');
    _addToHistory(LogEntry(
      level: 'DEBUG',
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  void info(String message) {
    _logger.i(message);
    _writeToFile('[INFO] $message');
    _addToHistory(LogEntry(
      level: 'INFO',
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  void warning(String message) {
    _logger.w(message);
    _writeToFile('[WARNING] $message');
    _addToHistory(LogEntry(
      level: 'WARNING',
      message: message,
      timestamp: DateTime.now(),
      isWarning: true,
    ));
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _writeToFile('[ERROR] $message | Error: $error');
    _addToHistory(LogEntry(
      level: 'ERROR',
      message: message,
      timestamp: DateTime.now(),
      isError: true,
      errorDetails: error.toString(),
    ));
  }

  void apiRequest({
    required String endpoint,
    required String method,
    required Map<String, dynamic>? requestBody,
    required Map<String, dynamic>? headers,
  }) {
    final message = '''
═══════════════════════════════════════════════════════════════
🌐 API REQUEST
═══════════════════════════════════════════════════════════════
Method: $method
Endpoint: $endpoint
Headers: ${jsonEncode(headers)}
Body: ${jsonEncode(requestBody)}
Timestamp: ${DateTime.now().toIso8601String()}
═══════════════════════════════════════════════════════════════
''';
    _logger.i(message);
    _writeToFile(message);
    _addToHistory(LogEntry(
      level: 'API_REQUEST',
      message: 'API Request: $method $endpoint',
      timestamp: DateTime.now(),
      details: {
        'method': method,
        'endpoint': endpoint,
        'headers': headers,
        'body': requestBody,
      },
    ));
  }

  void apiResponse({
    required String endpoint,
    required String method,
    required int statusCode,
    required dynamic responseBody,
    required Duration duration,
  }) {
    final message = '''
═══════════════════════════════════════════════════════════════
✅ API RESPONSE
═══════════════════════════════════════════════════════════════
Method: $method
Endpoint: $endpoint
Status Code: $statusCode
Duration: ${duration.inMilliseconds}ms
Response: ${jsonEncode(responseBody)}
Timestamp: ${DateTime.now().toIso8601String()}
═══════════════════════════════════════════════════════════════
''';
    _logger.i(message);
    _writeToFile(message);
    _addToHistory(LogEntry(
      level: 'API_RESPONSE',
      message: 'API Response: $method $endpoint ($statusCode)',
      timestamp: DateTime.now(),
      details: {
        'method': method,
        'endpoint': endpoint,
        'statusCode': statusCode,
        'duration': '${duration.inMilliseconds}ms',
        'response': responseBody,
      },
    ));
  }

  void apiError({
    required String endpoint,
    required String method,
    required int? statusCode,
    required String errorMessage,
    required Duration duration,
  }) {
    final message = '''
═══════════════════════════════════════════════════════════════
❌ API ERROR
═══════════════════════════════════════════════════════════════
Method: $method
Endpoint: $endpoint
Status Code: ${statusCode ?? 'N/A'}
Duration: ${duration.inMilliseconds}ms
Error: $errorMessage
Timestamp: ${DateTime.now().toIso8601String()}
═══════════════════════════════════════════════════════════════
''';
    _logger.e(message);
    _writeToFile(message);
    _addToHistory(LogEntry(
      level: 'API_ERROR',
      message: 'API Error: $method $endpoint',
      timestamp: DateTime.now(),
      isError: true,
      details: {
        'method': method,
        'endpoint': endpoint,
        'statusCode': statusCode,
        'duration': '${duration.inMilliseconds}ms',
        'error': errorMessage,
      },
    ));
  }

  void appEvent(String event, {Map<String, dynamic>? data}) {
    final message = '''
📱 APP EVENT: $event
Data: ${jsonEncode(data)}
Timestamp: ${DateTime.now().toIso8601String()}
''';
    _logger.i(message);
    _writeToFile(message);
    _addToHistory(LogEntry(
      level: 'APP_EVENT',
      message: event,
      timestamp: DateTime.now(),
      details: data,
    ));
  }

  void userAction(String action, {Map<String, dynamic>? data}) {
    final message = '''
👤 USER ACTION: $action
Data: ${jsonEncode(data)}
Timestamp: ${DateTime.now().toIso8601String()}
''';
    _logger.i(message);
    _writeToFile(message);
    _addToHistory(LogEntry(
      level: 'USER_ACTION',
      message: action,
      timestamp: DateTime.now(),
      details: data,
    ));
  }

  void authentication(String action, {Map<String, dynamic>? data}) {
    final message = '''
🔐 AUTH EVENT: $action
Data: ${jsonEncode(data)}
Timestamp: ${DateTime.now().toIso8601String()}
''';
    _logger.i(message);
    _writeToFile(message);
    _addToHistory(LogEntry(
      level: 'AUTH_EVENT',
      message: action,
      timestamp: DateTime.now(),
      details: data,
    ));
  }

  List<LogEntry> getLogHistory() => List.from(_logHistory);

  List<LogEntry> searchLogs(String query) {
    return _logHistory
        .where((log) =>
            log.message.toLowerCase().contains(query.toLowerCase()) ||
            log.level.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<String> getLogFilePath() async {
    return _logFile.path;
  }

  Future<String> getLogFileContent() async {
    return await _logFile.readAsString();
  }

  Future<void> clearLogs() async {
    try {
      _logHistory.clear();
      await _logFile.writeAsString('');
      info('Logs cleared');
    } catch (e) {
      error('Failed to clear logs', e);
    }
  }

  void printSeparator() {
    _logger
        .i('═══════════════════════════════════════════════════════════════');
  }
}

class LogEntry {
  final String level;
  final String message;
  final DateTime timestamp;
  final bool isError;
  final bool isWarning;
  final String? errorDetails;
  final Map<String, dynamic>? details;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.isError = false,
    this.isWarning = false,
    this.errorDetails,
    this.details,
  });

  String get formattedTime {
    return DateFormat('HH:mm:ss').format(timestamp);
  }

  String get formattedFullTime {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
  }

  @override
  String toString() {
    return '[$formattedTime] [$level] $message';
  }
}

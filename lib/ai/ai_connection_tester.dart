import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:petnote/logging/app_log_controller.dart';
import 'package:petnote/ai/ai_provider_config.dart';
import 'package:petnote/ai/ai_url_utils.dart';

class AiConnectionTestResult {
  const AiConnectionTestResult({
    required this.status,
    required this.message,
  });

  final AiConnectionStatus status;
  final String message;
}

class AiHttpRequest {
  const AiHttpRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
    this.timeout,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
  final Duration? timeout;
}

class AiHttpResponse {
  const AiHttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

abstract class AiHttpTransport {
  Future<AiHttpResponse> send(AiHttpRequest request);
}

class HttpClientAiHttpTransport implements AiHttpTransport {
  HttpClientAiHttpTransport({
    HttpClient Function()? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  static const Duration _defaultTimeout = Duration(seconds: 10);

  final HttpClient Function() _httpClientFactory;

  @override
  Future<AiHttpResponse> send(AiHttpRequest request) async {
    final client = _httpClientFactory();
    final timeout = request.timeout ?? _defaultTimeout;
    try {
      final httpRequest =
          await client.openUrl(request.method, request.uri).timeout(timeout);
      request.headers.forEach(httpRequest.headers.set);
      final requestBody = request.body;
      if (requestBody != null) {
        httpRequest.add(utf8.encode(requestBody));
      }
      final httpResponse = await httpRequest.close().timeout(timeout);
      final responseBody =
          await utf8.decoder.bind(httpResponse).join().timeout(timeout);
      return AiHttpResponse(
        statusCode: httpResponse.statusCode,
        body: responseBody,
      );
    } finally {
      client.close(force: true);
    }
  }
}

class AiConnectionTester {
  AiConnectionTester({
    AiHttpTransport? transport,
    this.appLogController,
  }) : _transport = transport ?? HttpClientAiHttpTransport();

  final AiHttpTransport _transport;
  final AppLogController? appLogController;

  Future<AiConnectionTestResult> testConnection({
    required AiProviderType providerType,
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    final normalizedBaseUrl = normalizeAiBaseUrl(baseUrl);
    appLogController?.info(
      category: AppLogCategory.ai,
      title: '开始测试 AI 连接',
      message:
          'provider=${providerType.name}, baseUrl=$normalizedBaseUrl, model=$model',
    );
    if (!isValidAiBaseUrl(normalizedBaseUrl)) {
      appLogController?.warning(
        category: AppLogCategory.ai,
        title: 'AI 连接测试失败',
        message: 'Base URL 格式不正确。',
      );
      return const AiConnectionTestResult(
        status: AiConnectionStatus.unreachable,
        message: 'Base URL 格式不正确，请检查完整的 http(s) 地址。',
      );
    }
    final candidateBaseUrls = _candidateBaseUrls(normalizedBaseUrl);
    AiConnectionTestResult? fallbackInvalidResponse;
    for (final candidateBaseUrl in candidateBaseUrls) {
      final attempt = await _attemptConnection(
        providerType: providerType,
        baseUrl: candidateBaseUrl,
        model: model,
        apiKey: apiKey,
      );
      if (attempt.status == AiConnectionStatus.success ||
          attempt.status == AiConnectionStatus.invalidKey ||
          attempt.status == AiConnectionStatus.modelUnavailable) {
        _logConnectionResult(attempt);
        return attempt;
      }
      if (attempt.status == AiConnectionStatus.invalidResponse) {
        fallbackInvalidResponse ??= attempt;
      }
    }
    final result = fallbackInvalidResponse ??
        const AiConnectionTestResult(
          status: AiConnectionStatus.unreachable,
          message: '连接失败，请检查网络和服务地址。',
        );
    _logConnectionResult(result);
    return result;
  }

  Future<AiConnectionTestResult> _attemptConnection({
    required AiProviderType providerType,
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    try {
      final request = switch (providerType) {
        AiProviderType.openai ||
        AiProviderType.openaiCompatible =>
          AiHttpRequest(
            method: 'GET',
            uri: Uri.parse('$baseUrl/models'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Accept': 'application/json',
            },
          ),
        AiProviderType.anthropic => AiHttpRequest(
            method: 'GET',
            uri: Uri.parse('$baseUrl/models'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'Accept': 'application/json',
            },
          ),
      };
      final response = await _transport.send(request);
      appLogController?.info(
        category: AppLogCategory.ai,
        title: 'AI 测试接口返回',
        message: '${request.method} ${request.uri} -> ${response.statusCode}',
        details: _previewResponseBody(response.body),
      );
      if (_shouldProbeChatCompletions(
        providerType: providerType,
        baseUrl: baseUrl,
        response: response,
      )) {
        return _probeStructuredChatCompletions(
          baseUrl: baseUrl,
          model: model,
          apiKey: apiKey,
        );
      }
      final parsed = _parseResponse(response: response, model: model);
      if (providerType == AiProviderType.openai &&
          parsed.status == AiConnectionStatus.success) {
        return _probeStructuredChatCompletions(
          baseUrl: baseUrl,
          model: model,
          apiKey: apiKey,
        );
      }
      if (providerType == AiProviderType.openaiCompatible &&
          parsed.status != AiConnectionStatus.invalidKey) {
        return _probeStructuredChatCompletions(
          baseUrl: baseUrl,
          model: model,
          apiKey: apiKey,
        );
      }
      return parsed;
    } on TimeoutException {
      appLogController?.warning(
        category: AppLogCategory.ai,
        title: 'AI 连接测试超时',
        message: '连接超时，请稍后重试。',
      );
      return const AiConnectionTestResult(
        status: AiConnectionStatus.timeout,
        message: '连接超时，请稍后重试。',
      );
    } on SocketException {
      appLogController?.warning(
        category: AppLogCategory.ai,
        title: 'AI 服务不可达',
        message: '服务地址不可达，请检查 Base URL。',
      );
      return const AiConnectionTestResult(
        status: AiConnectionStatus.unreachable,
        message: '服务地址不可达，请检查 Base URL。',
      );
    } catch (_) {
      appLogController?.error(
        category: AppLogCategory.ai,
        title: 'AI 连接测试异常',
        message: '连接失败，请检查网络和服务地址。',
      );
      return const AiConnectionTestResult(
        status: AiConnectionStatus.unreachable,
        message: '连接失败，请检查网络和服务地址。',
      );
    }
  }

  bool _shouldProbeChatCompletions({
    required AiProviderType providerType,
    required String baseUrl,
    required AiHttpResponse response,
  }) {
    if (providerType != AiProviderType.openaiCompatible) {
      return false;
    }
    if (!_looksLikeCloudflareWorkersAiUrl(baseUrl)) {
      return false;
    }
    return response.statusCode == 405;
  }

  bool _looksLikeCloudflareWorkersAiUrl(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) {
      return false;
    }
    return uri.host == 'api.cloudflare.com' &&
        uri.path.contains('/client/v4/accounts/') &&
        uri.path.endsWith('/ai/v1');
  }

  Future<AiConnectionTestResult> _probeStructuredChatCompletions({
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    var useStructuredOutput = true;
    var hasRetriedTransientFailure = false;
    while (true) {
      AiHttpResponse response;
      try {
        response = await _transport.send(
          _buildStructuredChatProbeRequest(
            baseUrl: baseUrl,
            model: model,
            apiKey: apiKey,
            useStructuredOutput: useStructuredOutput,
          ),
        );
      } on TimeoutException {
        if (!hasRetriedTransientFailure) {
          hasRetriedTransientFailure = true;
          appLogController?.warning(
            category: AppLogCategory.ai,
            title: 'AI 连接测试重试',
            message: '结构化探活请求超时，正在重试一次。',
          );
          continue;
        }
        rethrow;
      }
      if (_looksLikeStructuredOutputUnsupportedResponse(response) &&
          useStructuredOutput) {
        useStructuredOutput = false;
        continue;
      }
      if (_isRetryableProbeResponse(response) && !hasRetriedTransientFailure) {
        hasRetriedTransientFailure = true;
        appLogController?.warning(
          category: AppLogCategory.ai,
          title: 'AI 连接测试重试',
          message: '结构化探活遇到临时过载，正在重试一次。',
          details: 'status=${response.statusCode}',
        );
        continue;
      }
      return _parseStructuredChatCompletionsResponse(response);
    }
  }

  AiHttpRequest _buildStructuredChatProbeRequest({
    required String baseUrl,
    required String model,
    required String apiKey,
    required bool useStructuredOutput,
  }) {
    final body = <String, dynamic>{
      'model': model,
      'messages': const [
        {
          'role': 'system',
          'content': '只返回一个 JSON object，不要输出任何额外文字。',
        },
        {
          'role': 'user',
          'content': '请返回 {"ok":true}。',
        },
      ],
      'temperature': 0,
    };
    if (useStructuredOutput) {
      body['response_format'] = const {
        'type': 'json_object',
      };
    }
    return AiHttpRequest(
      method: 'POST',
      uri: Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  AiConnectionTestResult _parseResponse({
    required AiHttpResponse response,
    required String model,
  }) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.invalidKey,
        message: 'API Key 无效或没有访问权限。',
      );
    }
    if (response.statusCode == 404) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.unreachable,
        message: '服务地址不可达，请确认接口地址。',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return AiConnectionTestResult(
        status: AiConnectionStatus.unreachable,
        message: '连接失败，服务返回 ${response.statusCode}。',
      );
    }

    final decoded = _tryDecodeJson(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.invalidResponse,
        message: '服务响应异常，未返回合法 JSON。',
      );
    }
    final items = decoded['data'];
    if (items is! List) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.invalidResponse,
        message: '服务响应异常，未返回模型列表。',
      );
    }
    final modelIds = items
        .whereType<Map>()
        .map((item) => item['id'])
        .whereType<String>()
        .toSet();
    if (!modelIds.contains(model)) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.modelUnavailable,
        message: '当前模型不可用，请检查模型名称。',
      );
    }
    return const AiConnectionTestResult(
      status: AiConnectionStatus.success,
      message: '连接成功，可以开始使用 AI 功能。',
    );
  }

  AiConnectionTestResult _parseStructuredChatCompletionsResponse(
      AiHttpResponse response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.invalidKey,
        message: 'API Key 无效或没有访问权限。',
      );
    }
    if (response.statusCode == 404) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.unreachable,
        message: '服务地址不可达，请确认接口地址。',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return AiConnectionTestResult(
        status: AiConnectionStatus.unreachable,
        message: '连接失败，服务返回 ${response.statusCode}。',
      );
    }

    final decoded = _tryDecodeJson(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.invalidResponse,
        message: '服务响应异常，未返回合法 JSON。',
      );
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.invalidResponse,
        message: '服务响应异常，未返回聊天结果。',
      );
    }
    final content = _extractOpenAiMessageContent(decoded);
    if (content == null) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.invalidResponse,
        message: '服务响应异常，未返回文本内容。',
      );
    }
    if (_extractJsonObject(content) == null) {
      return const AiConnectionTestResult(
        status: AiConnectionStatus.invalidResponse,
        message: '连接成功但当前服务无法稳定返回结构化 JSON，暂不可用于 AI 总览生成。',
      );
    }
    return const AiConnectionTestResult(
      status: AiConnectionStatus.success,
      message:
          '基础连接成功，当前服务可返回结构化 JSON。正式生成较长报告仍可能受模型负载、上下文长度和超时影响。',
    );
  }

  bool _isRetryableProbeResponse(AiHttpResponse response) {
    return response.statusCode == 408 ||
        response.statusCode == 425 ||
        response.statusCode == 429 ||
        response.statusCode == 500 ||
        response.statusCode == 502 ||
        response.statusCode == 503 ||
        response.statusCode == 504;
  }

  bool _looksLikeStructuredOutputUnsupportedResponse(AiHttpResponse response) {
    if (response.statusCode < 400 || response.statusCode >= 500) {
      return false;
    }
    final decoded = _tryDecodeJson(response.body);
    final message = _findErrorMessage(decoded) ?? response.body;
    final normalized = message.toLowerCase();
    return normalized.contains('response_format') ||
        normalized.contains('json_schema') ||
        normalized.contains('json_object') ||
        normalized.contains('structured output');
  }

  String? _findErrorMessage(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      final errors = decoded['errors'];
      if (errors is List) {
        for (final item in errors) {
          if (item is Map<String, dynamic>) {
            final message = item['message'];
            if (message is String && message.trim().isNotEmpty) {
              return message.trim();
            }
          }
        }
      }
    }
    return null;
  }

  String? _extractOpenAiMessageContent(Map<String, dynamic> decoded) {
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return null;
    }
    final firstChoice = choices.first;
    if (firstChoice is! Map) {
      return null;
    }
    final message = firstChoice['message'];
    if (message is! Map) {
      return null;
    }
    final buffer = StringBuffer();
    _appendTextContent(message['content'], buffer);
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  void _appendTextContent(Object? value, StringBuffer buffer) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        buffer.writeln(trimmed);
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        _appendTextContent(item, buffer);
      }
      return;
    }
    if (value is Map) {
      if (value['text'] is String) {
        _appendTextContent(value['text'], buffer);
      }
      if (value['value'] is String) {
        _appendTextContent(value['value'], buffer);
      }
      if (value['content'] != null) {
        _appendTextContent(value['content'], buffer);
      }
      if (value['text'] == null &&
          value['value'] == null &&
          value['content'] == null) {
        for (final nested in value.values) {
          _appendTextContent(nested, buffer);
        }
      }
    }
  }

  Map<String, dynamic>? _extractJsonObject(String text) {
    final direct = _tryDecodeJson(text);
    if (direct is Map<String, dynamic>) {
      return direct;
    }

    final fencedMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    if (fencedMatch != null) {
      final fenced = _tryDecodeJson(fencedMatch.group(1)!.trim());
      if (fenced is Map<String, dynamic>) {
        return fenced;
      }
    }

    final startIndex = text.indexOf('{');
    if (startIndex == -1) {
      return null;
    }

    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = startIndex; index < text.length; index += 1) {
      final char = text[index];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) {
        continue;
      }
      if (char == '{') {
        depth += 1;
      } else if (char == '}') {
        depth -= 1;
        if (depth == 0) {
          final candidate = text.substring(startIndex, index + 1);
          final decoded = _tryDecodeJson(candidate);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
          return null;
        }
      }
    }
    return null;
  }

  List<String> _candidateBaseUrls(String normalizedBaseUrl) {
    final uri = Uri.tryParse(normalizedBaseUrl);
    if (uri == null) {
      return [normalizedBaseUrl];
    }
    final hasNoPath = uri.path.isEmpty || uri.path == '/';
    if (!hasNoPath) {
      return [normalizedBaseUrl];
    }
    return [
      normalizedBaseUrl,
      '$normalizedBaseUrl/v1',
    ];
  }

  Object? _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  void _logConnectionResult(AiConnectionTestResult result) {
    final level = switch (result.status) {
      AiConnectionStatus.success => AppLogLevel.info,
      AiConnectionStatus.invalidKey ||
      AiConnectionStatus.modelUnavailable ||
      AiConnectionStatus.timeout ||
      AiConnectionStatus.unreachable ||
      AiConnectionStatus.invalidResponse ||
      AiConnectionStatus.unavailable ||
      AiConnectionStatus.unknown =>
        AppLogLevel.warning,
    };
    appLogController?.log(
      level,
      category: AppLogCategory.ai,
      title: 'AI 连接测试结果',
      message: result.message,
      details: 'status=${result.status.name}',
    );
  }

  String _previewResponseBody(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'response body is empty';
    }
    if (trimmed.length <= 600) {
      return trimmed;
    }
    return '${trimmed.substring(0, 600)}…';
  }
}

import 'dart:convert';

enum AiProviderType {
  openai,
  anthropic,
  openaiCompatible,
  cloudflareWorkersAi,
}

enum AiConnectionStatus {
  unknown,
  success,
  invalidKey,
  unreachable,
  modelUnavailable,
  timeout,
  invalidResponse,
  unavailable,
}

class AiProviderConfig {
  const AiProviderConfig({
    required this.id,
    required this.displayName,
    required this.providerType,
    required this.baseUrl,
    required this.model,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastConnectionStatus = AiConnectionStatus.unknown,
    this.lastConnectionCheckedAt,
    this.lastConnectionMessage,
  });

  final String id;
  final String displayName;
  final AiProviderType providerType;
  final String baseUrl;
  final String model;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AiConnectionStatus lastConnectionStatus;
  final DateTime? lastConnectionCheckedAt;
  final String? lastConnectionMessage;

  AiProviderConfig copyWith({
    String? id,
    String? displayName,
    AiProviderType? providerType,
    String? baseUrl,
    String? model,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    AiConnectionStatus? lastConnectionStatus,
    DateTime? lastConnectionCheckedAt,
    String? lastConnectionMessage,
    bool clearLastConnectionCheckedAt = false,
    bool clearLastConnectionMessage = false,
  }) {
    return AiProviderConfig(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      providerType: providerType ?? this.providerType,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastConnectionStatus: lastConnectionStatus ?? this.lastConnectionStatus,
      lastConnectionCheckedAt: clearLastConnectionCheckedAt
          ? null
          : (lastConnectionCheckedAt ?? this.lastConnectionCheckedAt),
      lastConnectionMessage: clearLastConnectionMessage
          ? null
          : (lastConnectionMessage ?? this.lastConnectionMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'providerType': providerType.name,
      'baseUrl': baseUrl,
      'model': model,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastConnectionStatus': lastConnectionStatus.name,
      'lastConnectionCheckedAt': lastConnectionCheckedAt?.toIso8601String(),
      'lastConnectionMessage': lastConnectionMessage,
    };
  }

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) {
    return AiProviderConfig(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      providerType: aiProviderTypeFromName(json['providerType'] as String?),
      baseUrl: json['baseUrl'] as String? ??
          defaultBaseUrlForProvider(
            aiProviderTypeFromName(json['providerType'] as String?),
          ),
      model: json['model'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastConnectionStatus: aiConnectionStatusFromName(
        json['lastConnectionStatus'] as String?,
      ),
      lastConnectionCheckedAt: json['lastConnectionCheckedAt'] == null
          ? null
          : DateTime.parse(json['lastConnectionCheckedAt'] as String),
      lastConnectionMessage: json['lastConnectionMessage'] as String?,
    );
  }
}

AiProviderType aiProviderTypeFromName(String? value) => switch (value) {
      'anthropic' => AiProviderType.anthropic,
      'openaiCompatible' => AiProviderType.openaiCompatible,
      'cloudflareWorkersAi' => AiProviderType.cloudflareWorkersAi,
      _ => AiProviderType.openai,
    };

AiConnectionStatus aiConnectionStatusFromName(String? value) => switch (value) {
      'success' => AiConnectionStatus.success,
      'invalidKey' => AiConnectionStatus.invalidKey,
      'unreachable' => AiConnectionStatus.unreachable,
      'modelUnavailable' => AiConnectionStatus.modelUnavailable,
      'timeout' => AiConnectionStatus.timeout,
      'invalidResponse' => AiConnectionStatus.invalidResponse,
      'unavailable' => AiConnectionStatus.unavailable,
      _ => AiConnectionStatus.unknown,
    };

String aiProviderLabel(AiProviderType providerType) => switch (providerType) {
      AiProviderType.openai => 'OpenAI',
      AiProviderType.anthropic => 'Anthropic',
      AiProviderType.openaiCompatible => '兼容 OpenAI',
      AiProviderType.cloudflareWorkersAi => 'Cloudflare Workers AI',
    };

String defaultBaseUrlForProvider(AiProviderType providerType) =>
    switch (providerType) {
      AiProviderType.openai => 'https://api.openai.com/v1',
      AiProviderType.anthropic => 'https://api.anthropic.com/v1',
      AiProviderType.openaiCompatible => '',
      AiProviderType.cloudflareWorkersAi =>
        'https://api.cloudflare.com/client/v4/accounts/<account_id>/ai/v1',
    };

String cloudflareWorkersAiBaseUrlForAccountId(String accountId) {
  final normalizedAccountId = accountId.trim();
  return 'https://api.cloudflare.com/client/v4/accounts/'
      '$normalizedAccountId/ai/v1';
}

String cloudflareWorkersAiAccountIdFromBaseUrl(String baseUrl) {
  final normalizedBaseUrl = baseUrl.trim();
  final uri = Uri.tryParse(normalizedBaseUrl);
  if (uri == null) {
    return normalizedBaseUrl;
  }
  final segments = uri.pathSegments;
  final accountsIndex = segments.indexOf('accounts');
  if (accountsIndex == -1 || accountsIndex + 1 >= segments.length) {
    return normalizedBaseUrl;
  }
  final accountId = segments[accountsIndex + 1].trim();
  return accountId == '<account_id>' ? '' : accountId;
}

bool isValidCloudflareWorkersAiAccountId(String value) {
  final accountId = value.trim();
  if (accountId.isEmpty) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(accountId);
}

String aiConnectionStatusLabel(AiConnectionStatus status) => switch (status) {
      AiConnectionStatus.unknown => '尚未测试连接',
      AiConnectionStatus.success => '最近一次连接成功',
      AiConnectionStatus.invalidKey => 'API Key 无效或已失效',
      AiConnectionStatus.unreachable => '服务地址不可达',
      AiConnectionStatus.modelUnavailable => '当前模型不可用',
      AiConnectionStatus.timeout => '连接超时',
      AiConnectionStatus.invalidResponse => 'AI 端返回格式无法解析',
      AiConnectionStatus.unavailable => '当前平台安全存储不可用',
    };

String encodeAiProviderConfigs(List<AiProviderConfig> configs) {
  return jsonEncode(configs.map((config) => config.toJson()).toList());
}

List<AiProviderConfig> decodeAiProviderConfigs(String? rawJson) {
  if (rawJson == null || rawJson.isEmpty) {
    return const [];
  }
  final decoded = jsonDecode(rawJson);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map>()
      .map(
        (item) => AiProviderConfig.fromJson(
          item.map((key, value) => MapEntry('$key', value)),
        ),
      )
      .toList();
}

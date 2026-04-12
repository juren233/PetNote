import 'package:flutter_test/flutter_test.dart';
import 'package:petnote/ai/ai_provider_config.dart';
import 'package:petnote/state/app_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with no AI provider configs by default', () async {
    final controller = await AppSettingsController.load();

    expect(controller.aiProviderConfigs, isEmpty);
    expect(controller.activeAiProviderConfig, isNull);
  });

  test('persists AI provider configs and active selection across reload',
      () async {
    final controller = await AppSettingsController.load();
    final createdAt = DateTime.parse('2026-04-08T20:00:00+08:00');

    await controller.upsertAiProviderConfig(
      AiProviderConfig(
        id: 'cfg-openai',
        displayName: 'OpenAI 主账号',
        providerType: AiProviderType.openai,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-5.4',
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
        lastConnectionStatus: AiConnectionStatus.success,
        lastConnectionCheckedAt: createdAt,
        lastConnectionMessage: '连接成功',
      ),
    );

    final reloaded = await AppSettingsController.load();

    expect(reloaded.aiProviderConfigs, hasLength(1));
    expect(reloaded.activeAiProviderConfig?.id, 'cfg-openai');
    expect(
        reloaded.activeAiProviderConfig?.providerType, AiProviderType.openai);
    expect(
      reloaded.activeAiProviderConfig?.lastConnectionStatus,
      AiConnectionStatus.success,
    );
  });

  test('switching active provider keeps only one active config', () async {
    final controller = await AppSettingsController.load();
    final createdAt = DateTime.parse('2026-04-08T20:00:00+08:00');

    await controller.upsertAiProviderConfig(
      AiProviderConfig(
        id: 'cfg-openai',
        displayName: 'OpenAI 主账号',
        providerType: AiProviderType.openai,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-5.4',
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    await controller.upsertAiProviderConfig(
      AiProviderConfig(
        id: 'cfg-anthropic',
        displayName: 'Anthropic 备用',
        providerType: AiProviderType.anthropic,
        baseUrl: 'https://api.anthropic.com/v1',
        model: 'claude-sonnet-4-20250514',
        isActive: false,
        createdAt: createdAt,
        updatedAt: createdAt.add(const Duration(minutes: 1)),
      ),
    );

    await controller.setActiveAiProviderConfig('cfg-anthropic');

    final activeConfigs = controller.aiProviderConfigs
        .where((config) => config.isActive)
        .toList();
    expect(activeConfigs, hasLength(1));
    expect(activeConfigs.single.id, 'cfg-anthropic');
    expect(controller.activeAiProviderConfig?.id, 'cfg-anthropic');
  });

  test('deleting the active config clears active selection', () async {
    final controller = await AppSettingsController.load();
    final createdAt = DateTime.parse('2026-04-08T20:00:00+08:00');

    await controller.upsertAiProviderConfig(
      AiProviderConfig(
        id: 'cfg-openai',
        displayName: 'OpenAI 主账号',
        providerType: AiProviderType.openai,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-5.4',
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    await controller.upsertAiProviderConfig(
      AiProviderConfig(
        id: 'cfg-compatible',
        displayName: '兼容接口',
        providerType: AiProviderType.openaiCompatible,
        baseUrl: 'https://llm.example.com/v1',
        model: 'custom-model',
        isActive: false,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    await controller.deleteAiProviderConfig('cfg-openai');

    expect(controller.aiProviderConfigs, hasLength(1));
    expect(controller.activeAiProviderConfig, isNull);
  });
}

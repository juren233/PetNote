import 'package:flutter_test/flutter_test.dart';
import 'package:petnote/ai/ai_client_factory.dart';
import 'package:petnote/ai/ai_provider_config.dart';
import 'package:petnote/ai/ai_secret_store.dart';
import 'package:petnote/state/app_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns null when no active AI config exists', () async {
    final controller = await AppSettingsController.load();
    final factory = AiClientFactory(
      settingsController: controller,
      secretStore: InMemoryAiSecretStore(),
    );

    expect(await factory.createActiveClient(), isNull);
  });

  test('creates provider client from active config and stored secret',
      () async {
    final controller = await AppSettingsController.load();
    final secretStore = InMemoryAiSecretStore();
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
    await secretStore.writeKey('cfg-openai', 'sk-test-123');

    final factory = AiClientFactory(
      settingsController: controller,
      secretStore: secretStore,
    );
    final client = await factory.createActiveClient();

    expect(client, isNotNull);
    expect(client?.providerType, AiProviderType.openai);
    expect(client?.model, 'gpt-5.4');
    expect(client?.apiKey, 'sk-test-123');
  });

  test('returns null when active config base url is malformed', () async {
    final controller = await AppSettingsController.load();
    final secretStore = InMemoryAiSecretStore();
    final createdAt = DateTime.parse('2026-04-08T20:00:00+08:00');

    await controller.upsertAiProviderConfig(
      AiProviderConfig(
        id: 'cfg-broken',
        displayName: 'Broken',
        providerType: AiProviderType.openaiCompatible,
        baseUrl: '{"broken":true}',
        model: 'petnote-ai',
        isActive: true,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    await secretStore.writeKey('cfg-broken', 'sk-test-123');

    final factory = AiClientFactory(
      settingsController: controller,
      secretStore: secretStore,
    );

    expect(await factory.createActiveClient(), isNull);
  });
}

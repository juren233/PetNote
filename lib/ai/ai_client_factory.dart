import 'package:petnote/ai/ai_provider_config.dart';
import 'package:petnote/ai/ai_secret_store.dart';
import 'package:petnote/ai/ai_url_utils.dart';
import 'package:petnote/state/app_settings_controller.dart';

class AiProviderClient {
  const AiProviderClient({
    required this.configId,
    required this.providerType,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  final String configId;
  final AiProviderType providerType;
  final String baseUrl;
  final String model;
  final String apiKey;
}

class AiClientFactory {
  const AiClientFactory({
    required this.settingsController,
    required this.secretStore,
  });

  final AppSettingsController settingsController;
  final AiSecretStore secretStore;

  Future<AiProviderClient?> createActiveClient() async {
    final config = settingsController.activeAiProviderConfig;
    if (config == null) {
      return null;
    }
    if (config.model.trim().isEmpty || !isValidAiBaseUrl(config.baseUrl)) {
      return null;
    }
    final apiKey = await secretStore.readKey(config.id);
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }
    return AiProviderClient(
      configId: config.id,
      providerType: config.providerType,
      baseUrl: config.baseUrl,
      model: config.model,
      apiKey: apiKey,
    );
  }
}

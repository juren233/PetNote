import 'package:flutter_test/flutter_test.dart';
import 'package:petnote/ai/ai_secret_store.dart';

void main() {
  test('in-memory secret store supports write-read-delete lifecycle', () async {
    final store = InMemoryAiSecretStore();

    await store.writeKey('cfg-1', 'sk-test-123');
    expect(await store.readKey('cfg-1'), 'sk-test-123');

    await store.deleteKey('cfg-1');
    expect(await store.readKey('cfg-1'), isNull);
  });

  test('overwriting one config does not affect another stored key', () async {
    final store = InMemoryAiSecretStore();

    await store.writeKey('cfg-1', 'sk-old');
    await store.writeKey('cfg-2', 'sk-other');
    await store.writeKey('cfg-1', 'sk-new');

    expect(await store.readKey('cfg-1'), 'sk-new');
    expect(await store.readKey('cfg-2'), 'sk-other');
  });
}

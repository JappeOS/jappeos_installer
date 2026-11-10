import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:jappeos_installer/src/provider/install_provider.dart';

class FakeInstaller extends ChangeNotifier implements InstallerService {
  @override
  ServiceStatus status = ServiceStatus.loading;
  @override
  int generation = 0;
  @override
  Object? initializationError;
  Completer<LocaleInfo> locale = Completer<LocaleInfo>();
  Completer<StorageInfo> storage = Completer<StorageInfo>();
  int reads = 0;
  int retries = 0;
  @override
  Future<LocaleInfo> getLocaleInfo() {
    reads++;
    return locale.future;
  }

  @override
  Future<StorageInfo> getStorageInfo() => storage.future;
  @override
  Future<void> retryInitialization() async {
    retries++;
    change(ServiceStatus.ready);
  }

  void change(ServiceStatus next, {bool replace = false}) {
    if (replace) generation++;
    status = next;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LocaleInfo locale(String name) => LocaleInfo(
  locales: {name: name},
  timezones: [],
  keyboardLayouts: KeyboardLayoutInfo(layouts: {}),
);

void main() {
  testWidgets('slow startup publishes a complete snapshot', (tester) async {
    final service = FakeInstaller();
    final provider = InstallProvider(service);
    addTearDown(provider.dispose);
    expect(service.reads, 0);
    await tester.pump(const Duration(seconds: 4));
    service.change(ServiceStatus.ready);
    service.locale.complete(locale('en'));
    await tester.pump();
    expect(provider.localeInfo, isNull);
    expect(provider.isReady, false);
    service.storage.complete(StorageInfo(devices: {}));
    await tester.pump();
    expect(provider.isReady, true);
    expect(provider.loadingError, isNull);
  });

  testWidgets('read failure is visible and retry is coalesced', (tester) async {
    final service = FakeInstaller()..status = ServiceStatus.ready;
    final provider = InstallProvider(service);
    addTearDown(provider.dispose);
    service.locale.completeError(StateError('failed'));
    await tester.pump();
    expect(provider.loadingError, isA<StateError>());
    expect(provider.isReady, false);
    service.locale = Completer<LocaleInfo>();
    final first = provider.retryLoading();
    final second = provider.retryLoading();
    expect(service.reads, 2);
    service.locale.complete(locale('en'));
    service.storage.complete(StorageInfo(devices: {}));
    await tester.pump();
    await Future.wait([first, second]);
    expect(provider.isReady, true);
  });

  testWidgets('owner replacement discards old responses and refreshes', (
    tester,
  ) async {
    final service = FakeInstaller()..status = ServiceStatus.ready;
    final provider = InstallProvider(service);
    addTearDown(provider.dispose);
    final oldLocale = service.locale;
    service.change(ServiceStatus.unavailable, replace: true);
    service.locale = Completer<LocaleInfo>();
    service.change(ServiceStatus.ready);
    service.locale.complete(locale('new'));
    service.storage.complete(StorageInfo(devices: {}));
    await tester.pump();
    oldLocale.complete(locale('old'));
    await tester.pump();
    expect(provider.localeInfo!.locales.keys, ['new']);
    expect(provider.isReady, true);
  });

  testWidgets('snapshot timeout is bounded and late completion is ignored', (
    tester,
  ) async {
    final service = FakeInstaller()..status = ServiceStatus.ready;
    final provider = InstallProvider(
      service,
      loadTimeout: const Duration(seconds: 1),
    );
    addTearDown(provider.dispose);
    await tester.pump(const Duration(seconds: 2));
    expect(provider.loadingError, isA<TimeoutException>());
    service.locale.complete(locale('late'));
    service.storage.complete(StorageInfo(devices: {}));
    await tester.pump();
    expect(provider.localeInfo, isNull);
    expect(provider.isReady, false);
  });

  testWidgets('dispose during initial read causes no later notification', (
    tester,
  ) async {
    final service = FakeInstaller()..status = ServiceStatus.ready;
    final provider = InstallProvider(service);
    var notifications = 0;
    provider.addListener(() => notifications++);
    provider.dispose();
    service.locale.complete(locale('late'));
    service.storage.complete(StorageInfo(devices: {}));
    await tester.pump();
    expect(notifications, 0);
    expect(tester.takeException(), isNull);
  });
}

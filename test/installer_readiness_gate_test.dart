import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:jappeos_installer/src/provider/install_provider.dart';
import 'package:jappeos_installer/src/widgets/installer_readiness_gate.dart';

import 'install_provider_test.dart' show FakeInstaller, locale;

class Probe extends StatefulWidget {
  final VoidCallback onMount;
  const Probe({required this.onMount, super.key});
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const Text('Wizard');
}

void main() {
  testWidgets('spinner, failure, retry and recovery preserve wizard state', (
    tester,
  ) async {
    final service = FakeInstaller();
    final provider = InstallProvider(service);
    var mounts = 0;
    await tester.pumpWidget(
      ShadcnApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Scaffold(
            child: InstallerReadinessGate(
              child: Probe(onMount: () => mounts++),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Connecting to the installer…'), findsOneWidget);
    expect(mounts, 0);
    service.locale.complete(locale('en'));
    service.storage.complete(StorageInfo(devices: {}));
    service.change(ServiceStatus.ready);
    await tester.pumpAndSettle();
    expect(find.text('Wizard'), findsOneWidget);
    expect(mounts, 1);

    service.initializationError = StateError('Disconnected');
    service.change(ServiceStatus.failed, replace: true);
    await tester.pump();
    expect(find.text('Could not load the installer.'), findsOneWidget);
    expect(mounts, 1);
    service.initializationError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(service.retries, 1);
    expect(provider.isReady, true);
    expect(find.text('Could not load the installer.'), findsNothing);
    expect(mounts, 1);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
}

import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../provider/install_provider.dart';

/// Keep installer state mounted during recovery so reconnecting cannot re-run a
/// page's installation action. The overlay blocks navigation until data is ready.
class InstallerReadinessGate extends StatelessWidget {
  final Widget child;
  const InstallerReadinessGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallProvider>();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (provider.hasLoaded)
          ExcludeFocus(
            excluding: !provider.isReady,
            child: ExcludeSemantics(
              excluding: !provider.isReady,
              child: IgnorePointer(ignoring: !provider.isReady, child: child),
            ),
          ),
        if (!provider.isReady)
          ColoredBox(
            color: Theme.of(context).colorScheme.background,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.loadingError == null) ...[
                    const CircularProgressIndicator(),
                    const Gap(16),
                    const Text('Connecting to the installer…'),
                  ] else ...[
                    const Text('Could not load the installer.'),
                    const Gap(8),
                    const Text(
                      'Check that the installer service is available, then try again.',
                    ),
                    const Gap(16),
                    PrimaryButton(
                      onPressed: () => provider.retryLoading(),
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

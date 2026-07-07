//  jappeos_installer, Installer app for JappeOS.
//  Copyright (C) 2026  The JappeOS team.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:jappeos_installer/src/pages/installer_page.dart';
import 'package:jappeos_services/jappeos_services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../provider/install_provider.dart';
import '../widgets/centered_page_content.dart';
import '../widgets/page_title.dart';

class InstallationTypePage extends InstallerPage {
  InstallationTypePage() : super('Installation Type');

  @override
  List<Widget> widget(BuildContext context, int index) {
    return [const _InstallationTypePage()];
  }
}

class _InstallationTypePage extends StatefulWidget {
  const _InstallationTypePage();

  @override
  State<_InstallationTypePage> createState() => _InstallationTypePageState();
}

class _InstallationTypePageState extends State<_InstallationTypePage> {
  @override
  Widget build(BuildContext context) {
    final installProvider = context.watch<InstallProvider>();
    final scaling = Theme.of(context).scaling;
    return Expanded(child: RadioGroup(
      value: installProvider.selectedDiskInstallMode,
      onChanged: (v) => installProvider.selectedDiskInstallMode = v,

        child: CenteredPageContent(
          children: [
            const PageTitle(
              title: "Installation Type",
              subtitle: "Please select an installation type below.",
              alignment: CrossAxisAlignment.center,
            ),
            const RadioCard(
              value: InstallDiskMode.erase,
              child: Basic(
                title: Text('Erase'),
                content: Text('Erase an existing installation or empty hard drive completely, and install JappeOS.'),
              ),
            ),
            Gap(8 * scaling),
            const RadioCard(
              value: InstallDiskMode.manual,
              child: Basic(
                title: Text('Manual'),
                content: Text('If partitions are already set-up, pick mountpoints and install. This only overwrites selected partitions on the selected hard drive.'),
              ),
            ),
            Gap(8 * scaling),
            const RadioCard(
              value: InstallDiskMode.custom,
              child: Basic(
                title: Text('Custom'),
                content: Text('Edit partitions on a hard drive, then install JappeOS on the selected ones.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
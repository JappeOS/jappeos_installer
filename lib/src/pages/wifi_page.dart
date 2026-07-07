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
import 'package:shadcn_flutter/shadcn_flutter.dart';

class WifiPage extends InstallerPage {
  WifiPage() : super('WIFI');

  int wifiConnectRadioChoice = 0;

  @override
  List<Widget> widget(BuildContext context, int index) {
    return [
      const Text("Connect to the internet").h3(),
      Gap(2 * Theme.of(context).scaling),
      const Text("Connecting this device to a WIFI network allows you to install third-party-software, download updates, automatically detect your timezone, and install full support for your language.").muted(),
      SizedBox(height: 8 * Theme.of(context).scaling),
      /*ListTile(
        title: const Text('Do not connect me to a WIFI network.'),
        leading: Radio(
          value: 0,
          groupValue: wifiConnectRadioChoice,
          onChanged: (value) {
            setState(() {
              wifiConnectRadioChoice = value as int;
            });
          },
        ),
      ),
      ListTile(
        title: const Text('Connect to this network:'),
        leading: Radio(
          value: 1,
          groupValue: wifiConnectRadioChoice,
          onChanged: (value) {
            setState(() {
              wifiConnectRadioChoice = value as int;
            });
          },
        ),
      ),*/
      const Expanded(child: Placeholder()),
    ];
  }
}

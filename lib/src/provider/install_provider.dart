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

import 'dart:async';

import 'package:jappeos_services/jappeos_services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class InstallProvider extends ChangeNotifier {
  final InstallerService service;

  bool _disposed = false;
  bool _loading = false;
  Future<void>? _loadTask;
  bool _hasLoaded = false;
  bool _retrying = false;
  int _request = 0;
  int _serviceGeneration = -1;
  Object? _loadError;
  final Duration loadTimeout;

  InstallPlan _installPlan = InstallPlan(
    hostname: "",
    username: "",
    password: "",
    timezone: "",
    locale: "",
    keyboardLayout: ("", ""),
    disk: InstallDiskInfo.erase(""),
    installProprietary: true,
    installRecommendedDrivers: true,
  );

  InstallPlan get installPlan => _installPlan;

  set installPlan(InstallPlan val) {
    if (_installPlan != val) {
      _installPlan = val;
      notifyListeners();
    }
  }

  LocaleInfo? _localeInfo;
  StorageInfo? _storageInfo; /*= StorageInfo(
    devices: {
      "/dev/sda": StorageDeviceInfo(
        device: "/dev/sda",
        sizeMiB: 488281,
        partitions: [
          StoragePartitionInfo(
            device: "/dev/sda1",
            filesystem: StorageFilesystemType.fat32,
            sizeMiB: 159,
            mountPoint: "/boot",
          ),
          StoragePartitionInfo(
            device: "/dev/sda2",
            filesystem: StorageFilesystemType.ext4,
            sizeMiB: 488281 - 159 - 81380,
            mountPoint: "/",
          ),
          StoragePartitionInfo(
            device: "/dev/sda#free1",
            filesystem: StorageFilesystemType.freeSpace,
            sizeMiB: 81380,
            mountPoint: "",
          ),
        ],
      ),
    },
  );*/
  List<String> _planWarnings = [];
  InstallDiskMode _selectedDiskInstallMode = InstallDiskMode.erase;
  int _latestPlanId = 0;

  bool get hasLoaded => _hasLoaded;
  bool get isReady =>
      service.status == ServiceStatus.ready &&
      _localeInfo != null &&
      _storageInfo != null &&
      !_loading &&
      _loadError == null;
  Object? get loadingError => _loadError ?? service.initializationError;

  LocaleInfo? get localeInfo => _localeInfo;
  StorageInfo? get storageInfo => _storageInfo;
  List<String> get planWarnings => _planWarnings;
  InstallDiskMode get selectedDiskInstallMode => _selectedDiskInstallMode;

  set selectedDiskInstallMode(InstallDiskMode mode) {
    if (_selectedDiskInstallMode != mode) {
      _selectedDiskInstallMode = mode;
      notifyListeners();
    }
  }

  InstallProvider(
    this.service, {
    this.loadTimeout = const Duration(seconds: 30),
  }) {
    service.addListener(_onChanged);
    _onChanged();
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    service.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> createPlan() async {
    if (!isReady) throw StateError("Installer is not ready");

    final generation = service.generation;
    _planWarnings.clear();

    try {
      if (_latestPlanId != 0) {
        await service.cancelInstallPlan(_latestPlanId);
      }

      final res = await service.createInstallPlan(_installPlan);
      if (_disposed || generation != service.generation) {
        throw StateError("Installer changed while preparing the plan");
      }

      _latestPlanId = res.planId;
      _planWarnings = res.warnings;
    } finally {
      notifyListeners();
    }
  }

  Future<void> beginInstallation() async {
    if (!isReady || _latestPlanId == 0) {
      throw Exception("No install plan created yet");
    }
    await service.beginInstallation(_latestPlanId);
  }

  Future<void> retryLoading() async {
    if (_disposed || _retrying) return;
    _retrying = true;
    _loadError = null;

    try {
      if (service.status != ServiceStatus.ready) {
        await service.retryInitialization();
      }
      if (!_disposed) await _loadInitial();
    } catch (error) {
      if (!_disposed) _loadError = error;
    } finally {
      _retrying = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _loadInitial() {
    if (_loading) return _loadTask!;
    return _loadTask = _readInitial();
  }

  Future<void> _readInitial() async {
    if (_disposed || _loading || service.status != ServiceStatus.ready) return;

    final request = ++_request;
    _loading = true;
    _loadError = null;
    notifyListeners();

    try {
      // Publish one complete snapshot, never locale data from one daemon and
      // storage data from its replacement. These are read-only requests.
      final data = await (() async {
        final locale = await service.getLocaleInfo();
        final storage = await service.getStorageInfo();
        return (locale, storage);
      })().timeout(loadTimeout);

      if (_disposed || request != _request) return;

      _localeInfo = data.$1;
      _storageInfo = data.$2;
      _hasLoaded = true;
    } catch (error) {
      if (!_disposed && request == _request) _loadError = error;
    } finally {
      if (!_disposed && request == _request) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void _onChanged() {
    if (_disposed) return;

    if (_serviceGeneration != service.generation) {
      _serviceGeneration = service.generation;
      _request++;
      _loading = false;
      _loadError = null;
      _localeInfo = null;
      _storageInfo = null;
      _latestPlanId = 0;
      _planWarnings.clear();
    }

    if (service.status == ServiceStatus.ready &&
        _localeInfo == null &&
        !_loading &&
        _loadError == null) {
      unawaited(_loadInitial());
    }

    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}

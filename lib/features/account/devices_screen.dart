import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/domain/entities/app_device.dart';
import 'package:iptv/l10n/app_localizations.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _loading = true;
  String? _error;
  int _limit = 3;
  List<AppDevice> _devices = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(deviceRepositoryProvider).listDevices();
      if (!mounted) return;
      setState(() {
        _limit = result.deviceLimit;
        _devices = result.devices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _revoke(AppDevice device) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountRevokeDeviceTitle),
        content: Text(l10n.accountRevokeDeviceMessage(device.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.accountRevokeDeviceAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(deviceRepositoryProvider).revokeDevice(device.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(l10n.accountDevicesTitle),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(l10n.accountDeviceLimitLabel(_limit)),
                    const SizedBox(height: 12),
                    ..._devices.map((device) {
                      final active = device.isActive;
                      return ListTile(
                        title: Text(device.displayName),
                        subtitle: Text(
                          '${device.platform} · ${active ? l10n.accountDeviceActive : l10n.accountDeviceRevoked}',
                        ),
                        trailing: active
                            ? IconButton(
                                icon: const Icon(Icons.logout),
                                onPressed: () => _revoke(device),
                              )
                            : null,
                      );
                    }),
                  ],
                ),
    );
  }
}

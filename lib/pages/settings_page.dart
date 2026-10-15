import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme.dart';

/// الإعدادات: المظهر، والصوت والاهتزاز، وإدارة البيانات.
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService.instance;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _clearLogs() async {
    final bool ok = await showConfirmDialog(
      context,
      title: 'مسح سجل التطور',
      message: 'ستُحذف كل جلساتك المسجّلة وأرقامك. البرامج تبقى كما هي.',
      confirmLabel: 'مسح السجل',
    );
    if (!ok) return;
    await _storage.clearLogs();
    if (!mounted) return;
    _toast('تم مسح سجل التطور');
  }

  Future<void> _resetAll() async {
    final bool ok = await showConfirmDialog(
      context,
      title: 'مسح كل البيانات',
      message: 'ستُحذف كل برامجك وتمارينك وسجل تطورك نهائياً.',
      confirmLabel: 'مسح الكل',
    );
    if (!ok) return;
    await _storage.resetAllData();
    if (!mounted) return;
    _toast('تم مسح كل البيانات');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: AnimatedBuilder(
        animation: _storage,
        builder: (BuildContext context, Widget? _) {
          return _buildContent(context);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ThemeMode mode = _storage.themeMode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: <Widget>[
        // --- المظهر ---
        const SectionHeader(title: 'المظهر'),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _ThemeOption(
              label: 'داكن',
              icon: Icons.dark_mode_rounded,
              selected: mode == ThemeMode.dark,
              onTap: () => _storage.setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(width: 10),
            _ThemeOption(
              label: 'فاتح',
              icon: Icons.light_mode_rounded,
              selected: mode == ThemeMode.light,
              onTap: () => _storage.setThemeMode(ThemeMode.light),
            ),
            const SizedBox(width: 10),
            _ThemeOption(
              label: 'النظام',
              icon: Icons.phone_android_rounded,
              selected: mode == ThemeMode.system,
              onTap: () => _storage.setThemeMode(ThemeMode.system),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- التنبيهات أثناء التمرين ---
        const SectionHeader(title: 'أثناء التمرين'),
        const SizedBox(height: 10),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              SwitchListTile(
                value: _storage.soundEnabled,
                onChanged: (bool v) => _storage.setSoundEnabled(v),
                secondary: const Icon(Icons.volume_up_rounded),
                title: const Text(
                  'الصوت',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('نقرة صوتية عند العدّ التنازلي ونهاية الجولة'),
              ),
              const Divider(),
              SwitchListTile(
                value: _storage.vibrationEnabled,
                onChanged: (bool v) => _storage.setVibrationEnabled(v),
                secondary: const Icon(Icons.vibration_rounded),
                title: const Text(
                  'الاهتزاز',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('اهتزاز عند انتهاء الجولة أو الراحة'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- البيانات ---
        const SectionHeader(title: 'البيانات'),
        const SizedBox(height: 10),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text(
                  'مسح سجل التطور',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${_storage.logs.length} جلسة محفوظة'),
                onTap: _storage.logs.isEmpty ? null : _clearLogs,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.accent,
                ),
                title: const Text(
                  'مسح كل البيانات',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
                subtitle: Text('${_storage.programs.length} برنامج'),
                onTap: _resetAll,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- حول ---
        Center(
          child: Column(
            children: <Widget>[
              Text(
                'تماريني',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'الإصدار 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'بياناتك محفوظة على جوالك فقط',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    Key? key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fg = selected ? Colors.white : scheme.onSurfaceVariant;
    return Expanded(
      child: Material(
        color: selected ? AppColors.accent : AppTheme.surfaceHigh(context),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: <Widget>[
                Icon(icon, color: fg),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w800, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

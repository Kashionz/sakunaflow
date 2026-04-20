import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/providers/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);

    return preferences.when(
      data: (prefs) => ListView(
        padding: const EdgeInsets.fromLTRB(36, 28, 36, 48),
        children: [
          Text(
            '設定',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('帳號'),
          const _SettingsRow(label: '本地模式', value: 'Phase 1 不需登入'),
          const _SectionLabel('番茄鐘'),
          _DurationRow(label: '工作時長', value: prefs.workDuration),
          _DurationRow(label: '短休時長', value: prefs.shortBreakDuration),
          _DurationRow(label: '長休時長', value: prefs.longBreakDuration),
          const _SectionLabel('外觀'),
          const _SettingsRow(label: '主題模式', value: '跟隨系統'),
          const _SectionLabel('同步'),
          const _SettingsRow(label: '同步狀態', value: 'Phase 2 啟用'),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('設定載入失敗：$error')),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value, style: const TextStyle(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(label: label, value: '${value}m');
  }
}

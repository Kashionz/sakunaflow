import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../providers/database_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: ColoredBox(color: AppColors.background, child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  static const navItems = [
    _NavItem('/today', '今日', Icons.radio_button_unchecked),
    _NavItem('/calendar', '月曆', Icons.calendar_today_outlined),
    _NavItem('/pomodoro', '番茄鐘', Icons.adjust),
    _NavItem('/projects', '專案', Icons.grid_view_outlined),
    _NavItem('/stats', '統計', Icons.bar_chart_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final path = GoRouterState.of(context).uri.path;

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'S',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SakunaFlow',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final item in navItems)
                  _SidebarButton(
                    active:
                        path == item.path ||
                        (item.path == '/projects' &&
                            path.startsWith('/projects')),
                    icon: item.icon,
                    label: item.label,
                    onTap: () => context.go(item.path),
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 16, 8, 6),
                  child: Text(
                    '專案',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                projects.when(
                  data: (items) => Column(
                    children: [
                      for (final project in items)
                        _ProjectButton(
                          active: path == '/projects/${project.id}',
                          color: Color(
                            int.parse(project.color.substring(1), radix: 16) +
                                0xff000000,
                          ),
                          label: project.name,
                          onTap: () => context.go('/projects/${project.id}'),
                        ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _SidebarButton(
              active: path == '/settings',
              icon: Icons.settings_outlined,
              label: '設定',
              onTap: () => context.go('/settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [_SyncStatus()],
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          child: SizedBox(width: 6, height: 6),
        ),
        SizedBox(width: 6),
        Text(
          '本地模式',
          style: TextStyle(color: AppColors.mutedText, fontSize: 12),
        ),
      ],
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: TextButton.styleFrom(
          foregroundColor: active
              ? AppColors.primaryText
              : AppColors.secondaryText,
          backgroundColor: active
              ? const Color(0x12000000)
              : Colors.transparent,
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}

class _ProjectButton extends StatelessWidget {
  const _ProjectButton({
    required this.active,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: active
            ? AppColors.primaryText
            : AppColors.secondaryText,
        backgroundColor: active ? const Color(0x12000000) : Colors.transparent,
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox(width: 7, height: 7),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

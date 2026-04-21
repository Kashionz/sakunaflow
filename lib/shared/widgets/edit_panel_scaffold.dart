import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum EditSaveStatus { idle, saving, saved, failed }

class EditPanelScaffold extends StatelessWidget {
  const EditPanelScaffold({
    super.key,
    required this.title,
    required this.saveStatus,
    required this.child,
    this.errorMessage,
    this.onClose,
  });

  final String title;
  final EditSaveStatus saveStatus;
  final String? errorMessage;
  final VoidCallback? onClose;
  final Widget child;

  static const narrowBreakpoint = 720.0;
  static const widePanelWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panel = _PanelBody(
      title: title,
      saveStatus: saveStatus,
      errorMessage: errorMessage,
      onClose: onClose,
      child: child,
    );

    if (width < narrowBreakpoint) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          key: const ValueKey('edit-panel-narrow'),
          elevation: 16,
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: panel,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        key: const ValueKey('edit-panel-wide'),
        constraints: const BoxConstraints(
          maxWidth: widePanelWidth,
          minWidth: widePanelWidth,
          minHeight: double.infinity,
        ),
        child: Material(
          color: AppColors.background,
          elevation: 18,
          child: panel,
        ),
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.title,
    required this.saveStatus,
    required this.child,
    this.errorMessage,
    this.onClose,
  });

  final String title;
  final EditSaveStatus saveStatus;
  final String? errorMessage;
  final VoidCallback? onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      _SaveStatusLabel(
                        status: saveStatus,
                        errorMessage: errorMessage,
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: '關閉',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveStatusLabel extends StatelessWidget {
  const _SaveStatusLabel({required this.status, this.errorMessage});

  final EditSaveStatus status;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      EditSaveStatus.saving => '儲存中',
      EditSaveStatus.failed => '儲存失敗',
      EditSaveStatus.saved => '已儲存',
      EditSaveStatus.idle => '尚未變更',
    };
    final color = switch (status) {
      EditSaveStatus.failed => AppColors.red,
      EditSaveStatus.saving => AppColors.orange,
      _ => AppColors.mutedText,
    };

    return Text(
      errorMessage == null || status != EditSaveStatus.failed
          ? text
          : '$text：$errorMessage',
      style: TextStyle(color: color, fontSize: 12),
    );
  }
}

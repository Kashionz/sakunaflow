import 'dart:async';

import 'package:flutter/material.dart';

import 'edit_panel_scaffold.dart';

class DebouncedAutosaveField extends StatefulWidget {
  const DebouncedAutosaveField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onSave,
    this.fieldKey,
    this.onStatusChanged,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.isRequired = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final Future<void> Function(String value) onSave;
  final Key? fieldKey;
  final void Function(EditSaveStatus status, String? message)? onStatusChanged;
  final Duration debounceDuration;
  final bool isRequired;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  State<DebouncedAutosaveField> createState() => _DebouncedAutosaveFieldState();
}

class _DebouncedAutosaveFieldState extends State<DebouncedAutosaveField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  String? _errorText;
  String _lastSaved = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _lastSaved = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant DebouncedAutosaveField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue == widget.initialValue) {
      return;
    }
    if (_focusNode.hasFocus && _controller.text != _lastSaved) {
      return;
    }
    _controller.value = TextEditingValue(
      text: widget.initialValue,
      selection: TextSelection.collapsed(offset: widget.initialValue.length),
    );
    _lastSaved = widget.initialValue;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      onChanged: _scheduleSave,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: _errorText,
      ),
    );
  }

  void _scheduleSave(String value) {
    _debounce?.cancel();
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
    _debounce = Timer(widget.debounceDuration, () => _save(value));
  }

  Future<void> _save(String value) async {
    final trimmed = value.trim();
    if (widget.isRequired && trimmed.isEmpty) {
      setState(() => _errorText = '必填');
      return;
    }
    if (value == _lastSaved) {
      return;
    }

    widget.onStatusChanged?.call(EditSaveStatus.saving, null);
    try {
      await widget.onSave(value);
      _lastSaved = value;
      widget.onStatusChanged?.call(EditSaveStatus.saved, null);
    } catch (error) {
      widget.onStatusChanged?.call(EditSaveStatus.failed, error.toString());
    }
  }
}

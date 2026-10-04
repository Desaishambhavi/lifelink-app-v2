import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/security/report_encryption_service.dart';
import 'glass_controls.dart';

/// A modal bottom sheet that prompts for the report encryption passphrase.
///
/// Shows "create" mode (two fields) the first time, "enter" mode (one field)
/// on subsequent calls. Returns `true` once the [ReportEncryptionService]
/// singleton is unlocked; `false` if the user dismisses without unlocking.
class ReportPassphraseGate extends StatefulWidget {
  const ReportPassphraseGate._({required this.isFirstTime});
  final bool isFirstTime;

  /// Shows the gate and returns whether the service is now unlocked.
  ///
  /// A no-op (returns true) if the service is already unlocked this session.
  static Future<bool> show(BuildContext context) async {
    if (ReportEncryptionService.instance.isUnlocked) return true;
    final isFirstTime =
        !await ReportEncryptionService.instance.hasPassphrase();
    if (!context.mounted) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (_) => ReportPassphraseGate._(isFirstTime: isFirstTime),
    );
    return result == true;
  }

  @override
  State<ReportPassphraseGate> createState() => _ReportPassphraseGateState();
}

class _ReportPassphraseGateState extends State<ReportPassphraseGate> {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass = _passCtrl.text;
    if (pass.isEmpty) {
      setState(() => _error = 'Enter a passphrase');
      return;
    }
    if (widget.isFirstTime) {
      if (pass.length < 6) {
        setState(() => _error = 'Passphrase must be at least 6 characters');
        return;
      }
      if (pass != _confirmCtrl.text) {
        setState(() => _error = 'Passphrases do not match');
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.isFirstTime) {
        await ReportEncryptionService.instance.setPassphrase(pass);
      } else {
        await ReportEncryptionService.instance.unlock(pass);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on WrongPassphraseException {
      setState(() {
        _loading = false;
        _error = 'Incorrect passphrase — please try again';
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + bottom),
      decoration: BoxDecoration(
        color: AppColors.deep,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top:   BorderSide(color: AppColors.glassStroke),
          left:  BorderSide(color: AppColors.glassStroke),
          right: BorderSide(color: AppColors.glassStroke),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.white(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.mist),
              const SizedBox(width: 10),
              Text(
                widget.isFirstTime
                    ? 'Protect your reports'
                    : 'Unlock your reports',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isFirstTime
                ? "Create a passphrase to encrypt your report summaries. "
                    "You'll need it every time you generate or view them."
                : 'Enter your passphrase to decrypt and view your report summaries.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          _PassField(
            controller: _passCtrl,
            label: widget.isFirstTime ? 'Create passphrase' : 'Passphrase',
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
            onSubmit: widget.isFirstTime ? null : _submit,
          ),
          if (widget.isFirstTime) ...[
            const SizedBox(height: 12),
            _PassField(
              controller: _confirmCtrl,
              label: 'Confirm passphrase',
              obscure: _obscure,
              onToggle: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_error!,
                      style: TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          GlassButton(
            label: _loading
                ? (widget.isFirstTime ? 'Setting up…' : 'Unlocking…')
                : (widget.isFirstTime ? 'Set passphrase' : 'Unlock'),
            icon: Icons.lock_open_rounded,
            loading: _loading,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  const _PassField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.onSubmit,
  });
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
        style: TextStyle(color: AppColors.frost, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: AppColors.textTertiary, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}

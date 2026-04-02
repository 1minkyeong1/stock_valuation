import 'package:flutter/material.dart';
import 'package:stock_valuation_app/services/app_update_service.dart';
import 'package:stock_valuation_app/l10n/app_localizations.dart';

class UpdateCheckGate extends StatefulWidget {
  final Widget child;
  const UpdateCheckGate({super.key, required this.child});
  @override
  State<UpdateCheckGate> createState() => _UpdateCheckGateState();
}

class _UpdateCheckGateState extends State<UpdateCheckGate> {
  bool _didRun = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRun) return;
    _didRun = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppUpdateService.checkForUpdate();
      if (!mounted) return;
      if (!AppUpdateService.hasUpdate) return;
      final t = AppLocalizations.of(context)!;
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.updateAvailableTitle),
          content: Text(t.updateAvailableMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.updateLater),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.updateNow),
            ),
          ],
        ),
      );
      if (shouldUpdate == true) {
        await AppUpdateService.startImmediateUpdate();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

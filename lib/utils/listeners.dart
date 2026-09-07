import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AcessibleNotifyListenerNotifier with ChangeNotifier {
    void update() {
        notifyListeners();
    }
}

class BooruUpdateListener with ChangeNotifier {
    bool _notificationQueued = false;

    void update() {
        // Repository writes can complete while Flutter is in the middle of a
        // build/layout frame. Notifying synchronously in that phase makes
        // listeners call setState/markNeedsBuild during build, which can then
        // cascade into Navigator/GlobalKey assertions. Coalesce bursts of
        // repository changes and dispatch them once the current frame ends.
        if (_notificationQueued) return;
        _notificationQueued = true;

        Future<void>(() async {
            await SchedulerBinding.instance.endOfFrame;
            _notificationQueued = false;
            notifyListeners();
            counterListener.update();
        });
    }
}
BooruUpdateListener booruUpdateListener = BooruUpdateListener();

AcessibleNotifyListenerNotifier themeListener = AcessibleNotifyListenerNotifier();

AcessibleNotifyListenerNotifier counterListener = AcessibleNotifyListenerNotifier();

class LockListener with ChangeNotifier {
    bool isLocked = false;

    void unlock() {
        isLocked = false;
        notifyListeners();
    }

    void lock() {
        isLocked = true;
        notifyListeners();
    }
}
LockListener lockListener = LockListener();

class ImportListener with ChangeNotifier {
    bool isImporting = false;
    double progress = 0;

    void updateImportStatus({
        bool? import,
        double? progress
    }) {
        if(import != null) isImporting = import;
        if(progress != null) this.progress = progress;
        notifyListeners();
    }

    void clear() {
        updateImportStatus(
            import: false,
            progress: 0,
        );
    }
}
ImportListener importListener = ImportListener();
import Toybox.WatchUi;
import Toybox.Lang;

class PivoCounterDelegate extends WatchUi.BehaviorDelegate {

    var _view as PivoCounterView;

    function initialize(view as PivoCounterView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // UP tlačítko = přidat pivo
    function onPreviousPage() as Boolean {
        _view.addBeer();
        return true;
    }

    // DOWN tlačítko = přidat panák
    function onNextPage() as Boolean {
        _view.addShot();
        return true;
    }

    // BACK (dlouhý stisk) = reset s potvrzením
    function onBack() as Boolean {
        var dialog = new WatchUi.Confirmation("Reset počítadla?");
        WatchUi.pushView(dialog, new ResetConfirmDelegate(_view), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    // SELECT (střední tlačítko / tap) — zatím nic, lze rozšířit
    function onSelect() as Boolean {
        return true;
    }
}

// Potvrzovací dialog pro reset
class ResetConfirmDelegate extends WatchUi.ConfirmationDelegate {

    var _view as PivoCounterView;

    function initialize(view as PivoCounterView) {
        ConfirmationDelegate.initialize();
        _view = view;
    }

    function onResponse(response as WatchUi.Confirmation) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _view.reset();
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

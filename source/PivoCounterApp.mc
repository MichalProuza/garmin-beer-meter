import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class PivoCounterApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new PivoCounterView();
        var delegate = new PivoCounterDelegate(view);
        return [view, delegate];
    }
}

import Toybox.Graphics;
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

    // BACK = reset s potvrzením (vlastní dialog s vizuálními nápovědami)
    function onBack() as Boolean {
        var confirmView = new ResetConfirmView();
        var confirmDelegate = new ResetConfirmDelegate(_view);
        WatchUi.pushView(confirmView, confirmDelegate, WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    // SELECT — zatím nic, lze rozšířit
    function onSelect() as Boolean {
        return false;
    }
}

// ── Vlastní potvrzovací dialog s nápovědami tlačítek ──────────────────────
class ResetConfirmView extends WatchUi.View {

    function initialize() { View.initialize(); }
    function onLayout(dc as Dc) as Void {}

    function onUpdate(dc as Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // Pozadí
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, cx - 2);

        // Otázka
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.28).toNumber(), Graphics.FONT_SMALL, "Reset", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, (h * 0.40).toNumber(), Graphics.FONT_XTINY, "po\u010D\u00EDtadla?", Graphics.TEXT_JUSTIFY_CENTER);

        // Vodorovný dělič
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine((w * 0.15).toNumber(), (h * 0.53).toNumber(), (w * 0.85).toNumber(), (h * 0.53).toNumber());

        // ── NE — levá strana (tlačítko BACK, vlevo)
        dc.setColor(0xFF4444, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.07).toNumber(), (h * 0.57).toNumber(), Graphics.FONT_TINY, "\u25C4 NE", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.07).toNumber(), (h * 0.70).toNumber(), Graphics.FONT_XTINY, "BACK", Graphics.TEXT_JUSTIFY_LEFT);

        // Svislý dělič mezi volbami
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, (h * 0.54).toNumber(), cx, (h * 0.82).toNumber());

        // ── ANO — pravá strana (tlačítko SELECT, vpravo)
        dc.setColor(0x00CC55, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.93).toNumber(), (h * 0.57).toNumber(), Graphics.FONT_TINY, "ANO \u25BA", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.93).toNumber(), (h * 0.70).toNumber(), Graphics.FONT_XTINY, "SELECT", Graphics.TEXT_JUSTIFY_RIGHT);
    }
}

// ── Delegate pro vlastní dialog ─────────────────────────────────────────────
class ResetConfirmDelegate extends WatchUi.BehaviorDelegate {

    var _view as PivoCounterView;

    function initialize(view as PivoCounterView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // BACK = NE, zavřít bez resetu
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    // SELECT = ANO, provést reset
    function onSelect() as Boolean {
        _view.reset();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

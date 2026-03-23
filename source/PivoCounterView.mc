import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.Application.Storage;

class PivoCounterView extends WatchUi.View {

    var _piva as Number = 0;
    var _panaky as Number = 0;
    var _firstDrinkTime as Number or Null = null;
    var _lastDrinkTime as Number or Null = null;

    // ── Widmarkova rovnice ───────────────────────────────────────────────
    // BAC [promile] = alkohol_g / (r * váha_kg)
    // Metabolismus: 0.15 promile/h  →  ready = BAC_max / 0.15 hodin od prvního drinku
    static const WEIGHT_KG    = 80.0;
    static const WIDMARK_R    = 0.7;    // muž (žena = 0.6)
    static const METABOLISM   = 0.15;  // promile/h
    static const BEER_ALCOHOL_G = 19.725; // 0.5 l @ 5 %
    static const SHOT_ALCOHOL_G = 12.624; // 0.04 l @ 40 %

    // Seance se auto-resetuje po X hodinách od posledního drinku
    static const AUTO_RESET_HOURS = 6;

    function initialize() {
        View.initialize();
        _loadState();
        _checkAutoReset();
    }

    function onLayout(dc as Dc) as Void {}
    function onShow() as Void {}
    function onHide() as Void { _saveState(); }

    // =========================================================
    //  LAYOUT (relativní % z w / h):
    //   0–11 %   Název "PIVNÍ METR"
    //  11–13 %   dělič 1
    //  13–54 %   Počítadla: ikona | číslo | label
    //  54–55 %   dělič 2
    //  55–78 %   Promile (dominantní)
    //  78–87 %   Odhad řídit od + varování
    //  87–88 %   dělič 3
    //  88–96 %   start pití / poslední drink
    // =========================================================
    function onUpdate(dc as Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // ── Pozadí ──────────────────────────────────────────────────────
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, cx - 2);

        // ── Pomocné funkce ──────────────────────────────────────────────
        // (Monkey C nemá lokální lambda, použijeme přímé výpočty inline)

        var marginX = (w * 0.10).toNumber();
        var lCx     = (w * 0.26).toNumber();
        var rCx     = (w * 0.74).toNumber();

        var promile  = _calculatePromile();
        var pColor   = _getPromileColor(promile);
        var readySec = _calculateReadySec();

        // ── Název ────────────────────────────────────────────────────────
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.03).toNumber(), Graphics.FONT_TINY, "PIVNÍ METR", Graphics.TEXT_JUSTIFY_CENTER);

        // ── Dělič 1 ──────────────────────────────────────────────────────
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(marginX, (h * 0.13).toNumber(), w - marginX, (h * 0.13).toNumber());

        // ── Počítadla ─────────────────────────────────────────────────────
        // Ikony
        dc.setColor(0xFFCC00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, (h * 0.16).toNumber(), Graphics.FONT_LARGE, "🍺", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0xFF8833, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, (h * 0.16).toNumber(), Graphics.FONT_LARGE, "🥃", Graphics.TEXT_JUSTIFY_CENTER);

        // Čísla
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, (h * 0.28).toNumber(), Graphics.FONT_NUMBER_THAI_HOT, _piva.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rCx, (h * 0.28).toNumber(), Graphics.FONT_NUMBER_THAI_HOT, _panaky.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // Labely
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, (h * 0.48).toNumber(), Graphics.FONT_XTINY, "PIVA",   Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rCx, (h * 0.48).toNumber(), Graphics.FONT_XTINY, "PANÁKY", Graphics.TEXT_JUSTIFY_CENTER);

        // Svislý dělič
        dc.setColor(0x2a2a2a, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, (h * 0.14).toNumber(), cx, (h * 0.54).toNumber());

        // ── Dělič 2 ──────────────────────────────────────────────────────
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(marginX, (h * 0.55).toNumber(), w - marginX, (h * 0.55).toNumber());

        // ── Promile ───────────────────────────────────────────────────────
        dc.setColor(pColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.57).toNumber(), Graphics.FONT_NUMBER_MILD, promile.format("%.2f") + "‰", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.74).toNumber(), Graphics.FONT_XTINY, "ODHAD PROMILE", Graphics.TEXT_JUSTIFY_CENTER);

        // ── Řídit od / varování ───────────────────────────────────────────
        var delimY as Number;
        if (promile >= 0.8) {
            dc.setColor(0xFF3333, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.79).toNumber(), Graphics.FONT_TINY, "⚠ NEŘIĎ!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.86).toNumber(), Graphics.FONT_XTINY, "řídit od " + _formatTime(readySec), Graphics.TEXT_JUSTIFY_CENTER);
            delimY = (h * 0.90).toNumber();
        } else if (promile > 0.0) {
            var readyStr as String;
            if (readySec != null) {
                readyStr = "řídit od " + _formatTime(readySec);
                dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
            } else {
                readyStr = "teď v pohodě";
                dc.setColor(0x00CC55, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(cx, (h * 0.81).toNumber(), Graphics.FONT_TINY, readyStr, Graphics.TEXT_JUSTIFY_CENTER);
            delimY = (h * 0.87).toNumber();
        } else {
            dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.81).toNumber(), Graphics.FONT_XTINY, "střízlivý", Graphics.TEXT_JUSTIFY_CENTER);
            delimY = (h * 0.87).toNumber();
        }

        // ── Dělič 3 ──────────────────────────────────────────────────────
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(marginX, delimY, w - marginX, delimY);

        // ── Časy ──────────────────────────────────────────────────────────
        var t1y = delimY + (h * 0.06).toNumber();
        var t2y = delimY + (h * 0.12).toNumber();

        if (_firstDrinkTime != null) {
            dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
            dc.drawText(marginX, t1y, Graphics.FONT_XTINY, "start pití:", Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
            dc.drawText((w * 0.50).toNumber(), t1y, Graphics.FONT_XTINY, _formatTime(_firstDrinkTime), Graphics.TEXT_JUSTIFY_LEFT);

            dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
            dc.drawText(marginX, t2y, Graphics.FONT_XTINY, "poslední drink:", Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
            dc.drawText((w * 0.62).toNumber(), t2y, Graphics.FONT_XTINY, _formatTime(_lastDrinkTime), Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, t1y, Graphics.FONT_XTINY, "zatím střízlivý", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // ===== VÝPOČTY ========================================================

    function _calculatePromile() as Float {
        if (_piva == 0 && _panaky == 0) { return 0.0; }
        var totalAlcohol = (_piva * BEER_ALCOHOL_G) + (_panaky * SHOT_ALCOHOL_G);
        var bac = totalAlcohol / (WIDMARK_R * WEIGHT_KG);
        if (_firstDrinkTime != null) {
            var hoursElapsed = (Time.now().value() - _firstDrinkTime).toFloat() / 3600.0;
            bac -= METABOLISM * hoursElapsed;
            if (bac < 0.0) { bac = 0.0; }
        }
        return bac;
    }

    // Vrátí Unix timestamp (s), kdy BAC klesne na 0 — nebo null pokud už je 0
    function _calculateReadySec() as Number or Null {
        if (_piva == 0 && _panaky == 0) { return null; }
        var totalAlcohol = (_piva * BEER_ALCOHOL_G) + (_panaky * SHOT_ALCOHOL_G);
        var totalBac = totalAlcohol / (WIDMARK_R * WEIGHT_KG);
        var elapsedH = _firstDrinkTime != null
            ? (Time.now().value() - _firstDrinkTime).toFloat() / 3600.0
            : 0.0;
        var hoursLeft = totalBac / METABOLISM - elapsedH;
        if (hoursLeft <= 0.0) { return null; }
        return (Time.now().value() + (hoursLeft * 3600.0).toNumber());
    }

    function _getPromileColor(promile as Float) as Number {
        if (promile < 0.5) { return 0x00CC55; }
        if (promile < 0.8) { return 0xFFAA00; }
        return 0xFF3333;
    }

    // ===== AKCE ===========================================================

    function addBeer() as Void {
        _piva++;
        _updateDrinkTime();
        _saveState();
        WatchUi.requestUpdate();
    }

    function addShot() as Void {
        _panaky++;
        _updateDrinkTime();
        _saveState();
        WatchUi.requestUpdate();
    }

    function reset() as Void {
        _piva = 0; _panaky = 0;
        _firstDrinkTime = null; _lastDrinkTime = null;
        _saveState();
        WatchUi.requestUpdate();
    }

    function _updateDrinkTime() as Void {
        var now = Time.now().value();
        if (_firstDrinkTime == null) { _firstDrinkTime = now; }
        _lastDrinkTime = now;
    }

    // Auto-reset: pokud uplynulo více než AUTO_RESET_HOURS od posledního drinku
    function _checkAutoReset() as Void {
        if (_lastDrinkTime == null) { return; }
        var hoursSinceLast = (Time.now().value() - _lastDrinkTime).toFloat() / 3600.0;
        if (hoursSinceLast >= AUTO_RESET_HOURS.toFloat()) {
            _piva = 0; _panaky = 0;
            _firstDrinkTime = null; _lastDrinkTime = null;
            _saveState();
        }
    }

    // ===== FORMÁTOVÁNÍ ====================================================

    function _formatTime(timestamp as Number or Null) as String {
        if (timestamp == null) { return "--:--"; }
        var info = Gregorian.info(new Time.Moment(timestamp), Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    // ===== PERSISTENCE ====================================================

    function _saveState() as Void {
        Storage.setValue("piva",   _piva);
        Storage.setValue("panaky", _panaky);
        Storage.setValue("first",  _firstDrinkTime);
        Storage.setValue("last",   _lastDrinkTime);
    }

    function _loadState() as Void {
        var p = Storage.getValue("piva");
        var s = Storage.getValue("panaky");
        var f = Storage.getValue("first");
        var l = Storage.getValue("last");
        if (p != null) { _piva           = p; }
        if (s != null) { _panaky         = s; }
        if (f != null) { _firstDrinkTime = f; }
        if (l != null) { _lastDrinkTime  = l; }
    }
}

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

    static const WEIGHT_KG = 80.0;
    static const WIDMARK_R = 0.7;
    static const METABOLISM = 0.15;
    static const BEER_ALCOHOL_G = 19.725;
    static const SHOT_ALCOHOL_G = 12.624;
    static const AUTO_RESET_HOURS = 6;

    function initialize() {
        View.initialize();
        _loadState();
        _checkAutoReset();
    }

    function onLayout(dc as Dc) as Void {}

    function onShow() as Void {
        _checkAutoReset();
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        _saveState();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var marginX = (w * 0.12).toNumber();
        var leftCx = (w * 0.28).toNumber();
        var rightCx = (w * 0.72).toNumber();

        var promile = _calculatePromile();
        var promileColor = _getPromileColor(promile);
        var readySec = _calculateReadySec();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, cx - 2);

        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.05).toNumber(), Graphics.FONT_TINY, "PIVNI METR", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(marginX, (h * 0.14).toNumber(), w - marginX, (h * 0.14).toNumber());

        dc.setColor(0xFFCC00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, (h * 0.18).toNumber(), Graphics.FONT_TINY, "PIVO", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(leftCx, (h * 0.205).toNumber(), Graphics.FONT_XTINY, "0.5 l / 5 %", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0xFF8833, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightCx, (h * 0.18).toNumber(), Graphics.FONT_TINY, "PANAK", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightCx, (h * 0.205).toNumber(), Graphics.FONT_XTINY, "0.04 l / 40 %", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x2a2a2a, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, (h * 0.18).toNumber(), cx, (h * 0.43).toNumber());

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, (h * 0.25).toNumber(), Graphics.FONT_NUMBER_THAI_HOT, _piva.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightCx, (h * 0.25).toNumber(), Graphics.FONT_NUMBER_THAI_HOT, _panaky.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, (h * 0.40).toNumber(), Graphics.FONT_XTINY, "kusy", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightCx, (h * 0.40).toNumber(), Graphics.FONT_XTINY, "kusy", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(marginX, (h * 0.48).toNumber(), w - marginX, (h * 0.48).toNumber());

        dc.setColor(0x4a4a4a, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.52).toNumber(), Graphics.FONT_XTINY, "ODHAD PROMILE", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(promileColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.56).toNumber(), Graphics.FONT_NUMBER_MILD, promile.format("%.2f") + "\u2030", Graphics.TEXT_JUSTIFY_CENTER);

        if (promile >= 0.8) {
            dc.setColor(0xFF3333, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.70).toNumber(), Graphics.FONT_TINY, "NERID", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(0xBBBBBB, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.75).toNumber(), Graphics.FONT_XTINY, "ridit od " + _formatTime(readySec), Graphics.TEXT_JUSTIFY_CENTER);
        } else if (promile > 0.0 && readySec != null) {
            dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.72).toNumber(), Graphics.FONT_TINY, "ridit od " + _formatTime(readySec), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(0x00CC55, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.72).toNumber(), Graphics.FONT_TINY, "ted v pohode", Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(marginX, (h * 0.80).toNumber(), w - marginX, (h * 0.80).toNumber());

        if (_firstDrinkTime != null) {
            dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.84).toNumber(), Graphics.FONT_XTINY, "start " + _formatTime(_firstDrinkTime), Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(0x4d4d4d, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.89).toNumber(), Graphics.FONT_XTINY, "posledni " + _formatTime(_lastDrinkTime), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.86).toNumber(), Graphics.FONT_XTINY, "zatim bez zaznamu", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

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

    function _calculateReadySec() as Number or Null {
        if (_piva == 0 && _panaky == 0) { return null; }

        var totalAlcohol = (_piva * BEER_ALCOHOL_G) + (_panaky * SHOT_ALCOHOL_G);
        var totalBac = totalAlcohol / (WIDMARK_R * WEIGHT_KG);
        var elapsedH = _firstDrinkTime != null
            ? (Time.now().value() - _firstDrinkTime).toFloat() / 3600.0
            : 0.0;
        var hoursLeft = totalBac / METABOLISM - elapsedH;

        if (hoursLeft <= 0.0) { return null; }
        return Time.now().value() + (hoursLeft * 3600.0).toNumber();
    }

    function _getPromileColor(promile as Float) as Number {
        if (promile < 0.5) { return 0x00CC55; }
        if (promile < 0.8) { return 0xFFAA00; }
        return 0xFF3333;
    }

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
        _piva = 0;
        _panaky = 0;
        _firstDrinkTime = null;
        _lastDrinkTime = null;
        _saveState();
        WatchUi.requestUpdate();
    }

    function _updateDrinkTime() as Void {
        var now = Time.now().value();
        if (_firstDrinkTime == null) { _firstDrinkTime = now; }
        _lastDrinkTime = now;
    }

    function _checkAutoReset() as Void {
        if (_lastDrinkTime == null) { return; }

        var hoursSinceLast = (Time.now().value() - _lastDrinkTime).toFloat() / 3600.0;
        if (hoursSinceLast >= AUTO_RESET_HOURS.toFloat()) {
            _piva = 0;
            _panaky = 0;
            _firstDrinkTime = null;
            _lastDrinkTime = null;
            _saveState();
        }
    }

    function _formatTime(timestamp as Number or Null) as String {
        if (timestamp == null) { return "--:--"; }

        var info = Gregorian.info(new Time.Moment(timestamp), Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    function _saveState() as Void {
        Storage.setValue("piva", _piva);
        Storage.setValue("panaky", _panaky);
        Storage.setValue("first", _firstDrinkTime);
        Storage.setValue("last", _lastDrinkTime);
    }

    function _loadState() as Void {
        var p = Storage.getValue("piva");
        var s = Storage.getValue("panaky");
        var f = Storage.getValue("first");
        var l = Storage.getValue("last");

        if (p != null) { _piva = p; }
        if (s != null) { _panaky = s; }
        if (f != null) { _firstDrinkTime = f; }
        if (l != null) { _lastDrinkTime = l; }
    }
}

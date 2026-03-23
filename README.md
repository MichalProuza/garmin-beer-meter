# 🍺 Pivní čítač pro Garmin (Connect IQ Widget)

Jednoduchý widget pro Garmin Fenix / Epix, který ti počítá piva a panáky
a odhaduje promile pomocí Widmarkovy rovnice.

## Funkce
- **▲ UP** — přidat pivo (0.5l, 5 %)
- **▼ DOWN** — přidat panák (0.04l, 40 %)
- **BACK** (nebo dlouhý stisk) — reset s potvrzením
- Odhad promile v reálném čase (včetně metabolismu 0.15 ‰/h)
- Barevný indikátor: zelená / oranžová / červená
- Čas prvního a posledního drinku
- Délka pití v minutách
- Stav se uloží — přežije swipe pryč a vrátí se

## Instalace (vývojářský způsob)

### 1. Nainstaluj Connect IQ SDK
- Stáhni **Garmin Connect IQ SDK Manager** z:  
  https://developer.garmin.com/connect-iq/sdk/
- Nainstaluj SDK (vyžaduje Java / VS Code nebo Eclipse)
- Doporučeno: použij **Visual Studio Code** s rozšířením **Monkey C**

### 2. Otevři projekt
```
File → Open Folder → vyber složku PivoCounter/
```

### 3. Spusť na simulátoru
- `Ctrl+Shift+P` → "Monkey C: Run Current Application"
- Vyber zařízení: **fenix7** (nebo svůj model)

### 4. Nahraj do hodinek
- Připoj hodinky přes USB nebo Wi-Fi
- `Ctrl+Shift+P` → "Monkey C: Build for Device"
- Zkopíruj `.prg` soubor do hodinek: `GARMIN/APPS/`

## Přizpůsobení

V souboru `PivoCounterView.mc` lze změnit:
```
static const WEIGHT_KG = 80.0;   // tvoje váha v kg
static const WIDMARK_R = 0.7;    // 0.7 muž, 0.6 žena
static const METABOLISM = 0.15;  // promile/hodinu (individuální)
```

Pro pivo jiné síly nebo objem změň:
```
static const BEER_ALCOHOL_G = 19.725;  // 0.5l @ 5%
static const SHOT_ALCOHOL_G = 12.624;  // 0.04l @ 40%
```

## Výpočet promile

Používá **Widmarkovu rovnici**:
```
BAC = (alkohol_g) / (r × váha_kg)
BAC_aktuální = BAC - (0.15 × hodiny_od_prvního_drinku)
```

⚠️ **Upozornění**: Výpočet je pouze orientační. Skutečná hladina alkoholu
závisí na mnoha faktorech. Nikdy nesedej za volant, pokud jsi pil.

## Podporovaná zařízení
Fenix 5/6/7/8 (včetně AMOLED variant) a Epix 2 (viz manifest.xml pro úplný seznam)

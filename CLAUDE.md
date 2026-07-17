# Zarada — Claude Memory

Tracker zarade i isplata. Single-file SPA (`index.html`), crno + premium purple, Apple-clean.
Repo se zove `emmezeta-zarada`. "Emmezeta" se sada pojavljuje u UI-u (stats naslov, dashboard label, gumb u Postavkama) — ali app ostaje generička logika.

## Status
- **FINAL** — app gotova i u produkciji. Nema poznatih bugova.
- Mijenjaj samo na izričit zahtjev. Nakon promjene: verificiraj sintaksu (`node -e "new (require('vm').Script)(match[1])"`), commit, push.

## Pokretanje / deploy
- Otvori `index.html` u browseru (nema build, nema dependencija). Browser extension ne može file://, koristiti produkciju za browser testove.
- Produkcija: GitHub Pages → https://matijawork.github.io/emmezeta-zarada/
- Push na `main` → live za ~1 min.
- Sintaksa check: `node -e "const fs=require('fs');const html=fs.readFileSync('index.html','utf8');const match=html.match(/<script>([\s\S]*?)<\/script>/);new (require('vm').Script)(match[1]);console.log('OK');"`

## Datoteke
- `index.html` — SVE (HTML + CSS + JS inline u IIFE). Jedino što se uređuje.
- `data.json` — podaci u repu (primarni storage, app ga čita/piše preko GitHub API).
- `setup-laptop.sh` — generira setup URL i otvori browser (cross-device pomoć).

## Arhitektura
- **Storage**: GitHub API → `data.json` u repu (primary). `localStorage` = offline cache.
- **Auth**: GitHub token (`gh auth token` ili PAT). `OWNER='matijawork'` FIKSNO (const). Auth check = samo `pat()` (localStorage `gh_pat`). Onboarding pita SAMO token.
- **localStorage keys**: `gh_pat` (token), `gh_owner` (set ali se ne koristi), `ez_offline` (offline data fallback), `ez_zoom` (zoom %, per-uređaj).
- **Write**: `ghWrite()` uvijek svježi GET SHA prije PUT. `scheduleSave()` debounce 1000ms. Encoding `encData/decData` (TextEncoder/Decoder, UTF-8 → čšžćđ OK).
- **Live sync**: `refresh()` auto-pulla na focus/visibilitychange + `setInterval 20s` (`startLive()`). Guard: ne pulla ako `S.syncing||saveTimer` ni ako je INPUT/SELECT/TEXTAREA fokusiran.
- **State** `S`: view, data, sha, syncing/syncErr, e* (entry draft), p* (pay), si* (side), cal{open,target,month}, setupLink.
- **Render**: `renderView()` → `views[S.view]()` u `#mc`. Globalne fn na `window.*` za onclick.

## Viewovi (nav redoslijed: Pregled / Unos / Novac / Isplata / Postavke)

- **dashboard** `vDash`: brand badge (aktovka), hero "Ukupno zarađeno" (`totalEarned+totalSide`), grid2 Emmezeta/Sa strane. BEZ liste smjena, BEZ duga ovdje (dug je u Isplati).

- **entry** `vEntry`: datum (custom kalendar) → **nedjelja auto-postavlja +50%** (`calPick` detektira `getDay()===0`), 6 preset chipova (08–14, 08–16, 09–17, 10–18, 12–18, 12–20), 2× time dropdown, +50% toggle (`eDouble`), >8h crveno upozorenje, calc preview, "Spremi smjenu" (nakon spremi `eDouble` ostaje sinkroniziran s datumom, ne resetira na false uvijek), **"Sve smjene"** lista (✕ `delShift`).

- **verify** `vPay`: hero "Dug roditelja" (`cumDebt`), datum, iznos input → live preview `presHTML()` (`pCalc` updejta samo #pres bez re-rendera), lista isplata (✕ `delPay`).

- **money** `vMoney`: hero strana zarada, datum + izvor (`si-source`, chip dropdown izvora `mSrc(i)` šalje INDEX, ne string) + iznos, lista (✕ `delSide`). `readSide()` DOM→state na oninput bez re-rendera.

- **settings** `vSettings`: gumb "📊 Emmezeta statistika →" (→ `go('stats')`), Osobni podaci (ime, satnica), Prikaz (zoom chips), Spajanje uređaja (`genLink`/`copyLink`), Račun (Odjava `logout`), Zona opasnosti (`clearAll`). **Nema "Svi podaci" sekcije** — brisanje je direktno u svakom viewu.

- **stats** `vStats` (sub-view Postavki, nav ne postoji — Postavke nav ostaje aktivan): ukupno sati card, grid2 Radni dani/Nedjelja sati, CSS grid tablica po mjesecima (`grid-template-columns:1fr 66px 66px 66px`) s headerom/podacima, subtitle "Ukupno N · Radno N · Ned N". Klasificira: `getDay()===0` = nedjelja (ne subota). Gumb ← Natrag.

- **onboarding** `renderOnboarding`: aktovka 💼 badge + token input + `gh auth token` hint + "Spoji".

## data.json shape
```json
{
  "config": { "hourlyRate": 6.56, "ownerName": "Matija" },
  "shifts": [{ "id": "uuid", "date": "2026-06-15", "startTime": "08:00", "endTime": "16:00", "double": false }],
  "payments": [{ "id": "uuid", "date": "2026-06-22", "amount": 260.0, "weekKey": "2026-W26", "note": "" }],
  "sideIncome": [{ "id": "uuid", "date": "2026-06-21", "amount": 80.0, "source": "Baustela" }]
}
```
- `double` = +50% po smjeni (auto-set za nedjelju, može se ručno override). `weekKey` = `isoWeek(date)`, piše se za back-compat ali se NE koristi za prikaz.
- Migracija na load: ako `sideIncome` nije array → `[]`.

## Izračuni
- `baseRate()` = config.hourlyRate ?? 6.56. `PREMIUM = 1.5` (+50%, NIJE ×2).
- `shiftRate(sh)` = `money(baseRate() × (sh.double ? 1.5 : 1))`.
- `shiftEarned(sh)` = `money(calcHours(sh.startTime,sh.endTime) × shiftRate(sh))`.
- `calcHours(start,end)`: preko ponoći → `if(e<=s) e+=1440`.
- `MAXH = 8` → calcHours > 8 → crveno upozorenje.
- `totalEarned` = Σ shiftEarned, `totalPaid` = Σ payments.amount, `cumDebt` = earned − paid (SAMO Emmezeta; strana zarada NE dira dug).
- `totalSide` = Σ sideIncome.amount; `sideSources()` = unique izvori → chips.
- `money(x)` = `Math.round(x*100)/100`. `fmt(n)` = `toFixed(2)` s zarezom.
- `PRESETS`: 08–14, 08–16, 09–17, 10–18, 12–18, 12–20.
- `todayStr()` — koristi **lokalni datum** (`getDate/getMonth/getFullYear`), ne `toISOString()` (bio UTC bug).

## Custom kalendar
- `dateField(target,ds)` = trigger gumb → `openCal(target)`. Target: 'shift'|'pay'|'side'.
- `calOverlay()` render (Mon-first, MONTHS_FULL), `calNav(±1)`, `calPick(ds)`, `closeCal()`.
- `calPick`: za 'shift' auto-postavlja `S.eDouble = getDay()===0` (nedjelja = +50%).

## Zoom (per-uređaj)
- Postavke → "Prikaz" chipovi 90/100/110/125/150%. Sprema u `localStorage.ez_zoom`.
- `applyZoom()` pozvan u BOOT prije `init()` → persist kroz reload.

## Logout
- `window.logout`: `clearTimeout(saveTimer)` → `localStorage.clear()` → `location.reload()`.

## Cross-device setup
- URL: `https://matijawork.github.io/emmezeta-zarada/#setup-OWNER_B64-TOKEN_B64` (b64url).
- `init()` čita hash → localStorage → briše hash → nastavlja.

## Konvencije / gotchas
- Sve user-tekst kroz `esc()` prije u HTML (XSS-safe).
- Globalni shortcuti: Esc→closeCal; Enter→submit po viewu (entry:saveEntry, verify:recPay, money:addSide, settings:saveCfg). 'stats' view nema Enter handler.
- `renderView()` views mapa uključuje `stats:vStats`. Nav active logic: `settings` nav aktivan i kad je view==='stats'.
- `dataBlock()` funkcija još postoji u kodu ali nigdje se ne poziva — dead code, harmless.
- iPhone: viewport-fit=cover + apple-web-app meta + safe-area-inset. Inputi 16px → nema iOS zoom.
- gh token komande blokira classifier → korisnik ih sam pokrene u Terminalu.

## TODO
- Nema. Ako korisnik traži izmjenu: napravi, verificiraj sintaksom, commit + push, pa ažuriraj ovaj CLAUDE.md.

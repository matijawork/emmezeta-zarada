# Zarada — Claude Memory

Tracker zarade i isplata. Single-file SPA (`index.html`), crno + premium purple, Apple-clean.
Repo se zove `emmezeta-zarada` (infra ime), ali app je **generički** — u UI-u se NIGDJE ne spominje "Emmezeta".

## Status
- **FINAL** — app gotova i u produkciji. Nema poznatih bugova.
- Mijenjaj samo na izričit zahtjev. Nakon promjene: verificiraj (vidi dolje), commit, push.

## Pokretanje / deploy
- Otvori `index.html` u browseru (nema build, nema dependencija).
- Produkcija: GitHub Pages → https://matijawork.github.io/emmezeta-zarada/
- Push na `main` → live za ~1 min. Cache-bust: dodaj `?v=<sha>`.
- **Verifikacija promjena** (lokalno, bez tokena/networka): headless Chrome screenshot.
  - `node --check` na izvučenom JS-u za sintaksu.
  - Za viewove koji trebaju podatke: ubaci `<script>` koji stubа `window.fetch` (vrati `{ok,status:200,json:()=>({sha,content})}` gdje je `content` = base64 od `JSON.stringify(sample)`) i `localStorage.gh_pat`. Onda `--screenshot`.

## Datoteke
- `index.html` — SVE (HTML + CSS + JS inline u IIFE). Jedino što se uređuje.
- `data.json` — podaci u repu (primarni storage, app ga čita/piše preko GitHub API).
- `setup-laptop.sh` — generira setup URL i otvori browser (cross-device pomoć).

## Arhitektura
- **Storage**: GitHub API → `data.json` u repu (primary). `localStorage` = offline cache.
- **Auth**: GitHub token (`gh auth token` ili PAT). `OWNER='matijawork'` FIKSNO (const) — owner() ignorira localStorage. Auth check = samo `pat()` (localStorage `gh_pat`). Onboarding pita SAMO token.
- **localStorage keys**: `gh_pat` (token), `gh_owner` (set ali se ne koristi), `ez_offline` (offline data fallback), `ez_zoom` (zoom %, per-uređaj).
- **Write**: `ghWrite()` uvijek svježi GET SHA prije PUT. `scheduleSave()` debounce 1000ms. Encoding `encData/decData` (TextEncoder/Decoder, UTF-8 → čšžćđ OK).
- **Live sync**: `refresh()` auto-pulla na focus/visibilitychange + `setInterval 20s` (`startLive()`). Guard: ne pulla ako `S.syncing||saveTimer` ni ako je INPUT/SELECT/TEXTAREA fokusiran. `saveTimer=null` nakon fire (inače guard zauvijek blokira).
- **State** `S`: view, data, sha, syncing/syncErr, e* (entry draft), p* (pay), si* (side), cal{open,target,month}, setupLink.
- **Render**: `renderView()` → `views[S.view]()` u `#mc`. Globalne fn na `window.*` za onclick.

## Viewovi (nav redoslijed: Pregled / Unos / Novac / Isplata / Postavke)
- **dashboard** `vDash`: brand badge (aktovka), hero "Dug roditelja" (`cumDebt`), grid2 Zarađeno/Isplaćeno, "Zarađeno sa strane" stat (ako >0), **"Ukupna zarada"** card = `totalEarned()+totalSide()`. NEMA liste smjena (briše se u Postavkama).
- **entry** `vEntry`: datum (custom kalendar), preset chipovi, 2× time dropdown (`timeSelects`/`eSetTime`), +50% toggle (`eDouble`), >8h crveno upozorenje, calc preview, "Spremi smjenu", pa **"Sve smjene"** lista (svih smjena desc, ✕ `delShift`).
- **verify** `vPay`: hero dug, datum, iznos input → live preview `presHTML()` (`pCalc` updejta samo #pres, bez re-rendera = fokus ostaje), lista isplata.
- **money** `vMoney`: hero strana zarada, datum + izvor (`si-source`, chip dropdown izvora `mSrc(i)` šalje INDEX, ne string) + iznos, lista. `readSide()` DOM→state na oninput bez re-rendera.
- **settings** `vSettings`: Osobni podaci (ime, satnica), **Prikaz** (zoom chips), Spajanje uređaja (`genLink`/`copyLink`), Svi podaci (`dataBlock` → `delShift`/`delPay`/`delSide`), Račun (Status Povezano + **Odjava** `logout`), Zona opasnosti (`clearAll`).
- **onboarding** `renderOnboarding`: aktovka 💼 badge + token input + jedna linija `gh auth token` + "Spoji".

## data.json shape
```json
{
  "config": { "hourlyRate": 6.56, "ownerName": "Matija" },
  "shifts": [{ "id": "uuid", "date": "2026-06-15", "startTime": "07:00", "endTime": "15:00", "double": false }],
  "payments": [{ "id": "uuid", "date": "2026-06-22", "amount": 260.0, "weekKey": "2026-W26", "note": "" }],
  "sideIncome": [{ "id": "uuid", "date": "2026-06-21", "amount": 80.0, "source": "Baustela" }]
}
```
- `double` = ručni +50% po smjeni. `weekKey` = `isoWeek(date)`, piše se za back-compat ali se NE koristi za prikaz (jedini razlog da `isoWeek()` postoji).
- Migracija na load: ako `sideIncome` nije array → `[]`. (Stari `expenses` ne postoji više.)

## Izračuni
- `baseRate()` = config.hourlyRate ?? 6.56. `PREMIUM = 1.5` (+50%, NIJE ×2).
- `shiftRate(sh)` = baseRate × (sh.double ? 1.5 : 1). `shiftEarned` = sati × shiftRate.
- `calcHours(start,end)`: preko ponoći → `if(e<=s) e+=1440`.
- `MAXH = 8` → calcHours > 8 → crveno upozorenje (Matija ne smije >8h).
- `totalEarned` = Σ shiftEarned, `totalPaid` = Σ payments.amount, `cumDebt` = earned − paid (SAMO posao; strana zarada NE dira dug).
- `totalSide` = Σ sideIncome.amount; `sideSources()` = unique izvori → chips (auto-update).
- Sav novac: `money(x) = Math.round(x*100)/100`. Prikaz `fmt(n)` = `toFixed(2)` s zarezom.
- `PRESETS`: 08–16, 09–17, 10–18, 12–18, 12–20. Radi za SVE datume (nema više START/END raspona).

## Custom kalendar
- `dateField(target,ds)` = trigger gumb → `openCal(target)`. Target: 'shift'|'pay'|'side'.
- `calOverlay()` render (Mon-first, MONTHS_FULL), `calNav(±1)`, `calPick(ds)`, `closeCal()`. Prije otvaranja sprema utipkano (`readSide`/`readPay`).

## Zoom (per-uređaj)
- Postavke → "Prikaz" chipovi 90/100/110/125/150%. Sprema u `localStorage.ez_zoom`.
- `curZoom()` / `applyZoom()` (`document.documentElement.style.zoom = z/100`), `setZoom(z)`.
- `applyZoom()` pozvan u BOOT prije `init()` → persist kroz reload. NIJE u data.json (device-specific).

## Logout
- `window.logout`: `clearTimeout(saveTimer)` → `localStorage.clear()` → `location.reload()` → onboarding. GitHub podaci ostaju; novi token = čist start.

## Cross-device setup
- URL: `https://matijawork.github.io/emmezeta-zarada/#setup-OWNER_B64-TOKEN_B64` (b64url `b64e`/`b64d`).
- `init()` čita hash → localStorage → briše hash → nastavlja. Mobitel: Postavke → "Generiraj setup link".

## Konvencije / gotchas
- Sve user-tekst kroz `esc()` prije u HTML (XSS-safe).
- Globalni shortcuti (startLive keydown): Esc→closeCal; Enter→submit po viewu (entry:saveEntry, verify:recPay, money:addSide, settings:saveCfg); ob-p ima svoj handler.
- iPhone: viewport-fit=cover + apple-web-app meta + safe-area-inset (main/toasts/nav). Inputi 16px → nema iOS zoom.
- Komande s gh tokenima blokira classifier → korisnik ih sam pokrene u Terminalu.
- CSS: `:root` varijable, `.btn-primary` glossy gradient + glow, `.card.list` za liste, brand badge aktovka.

## TODO
- Nema. Ako korisnik traži izmjenu: napravi, verificiraj screenshotom, commit + push, pa ažuriraj ovaj CLAUDE.md.

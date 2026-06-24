# emmezeta-zarada — Claude Memory

## Status
- Zadnja sesija: 2026-06-24 (NOVO: tab "Novac" — strana zarada s izvorima + potrošnja, gotovina = strana − potrošeno)
- Faza: complete (čeka testiranje od Matije)

## Što je gotovo
- [x] Git setup + GitHub public repo (matijawork/emmezeta-zarada)
- [x] index.html — full black + premium purple dizajn, single file SPA
- [x] Dnevni unos: datum, početak, kraj → auto sati, stopa, zarada
- [x] Tjedni izračuni (ISO tjedni, ponedjeljak–nedjelja)
- [x] Kumulativni dug logika (ukupno zarađeno − ukupno isplaćeno)
- [x] Verifikacija isplate (tjedna provjera + evidencija)
- [x] GitHub API sync (read/write, debounce 1s, offline fallback)
- [x] Auto-setup via URL hash (#setup-OWNER_B64-TOKEN_B64)
- [x] Onboarding ekran (username + token, objašnjava `gh auth token`)
- [x] setup-laptop.sh — auto generira setup URL i otvara browser
- [x] Postavke: "Generiraj setup link za mobitel" → kopiraj URL → otvori na mobitelu
- [x] GitHub Pages deploy — https://matijawork.github.io/emmezeta-zarada/
- [x] Satnica 6.56 €/h (rework 2026-06-19)
- [x] Ručni ×2 toggle po smjeni (shift.double) — maknut auto nedjelja/blagdani ×2
- [x] Redizajn unosa: brze smjene (chips), Danas/Jučer datum, time pickeri
- [x] >8h crveno upozorenje (Matija ne smije >8h)
- [x] Maknut workDaysLeft brojač + Blagdani sekcija + mrtvi CSS/tekst
- [x] Edge cases: smjena preko ponoći, ručni ×2, offline fallback
- [x] Tab "Novac" (5. nav): strana zarada + potrošnja (2026-06-24)
- [x] Strana zarada: datum + izvor (ime) + iznos; izvori se pamte → chip dropdown (derivirano iz unosa, auto-update)
- [x] Potrošnja: datum + opis + iznos; oduzima SAMO od strane zarade (Emmezeta netaknuta)
- [x] Stanje gotovine = totalSide() − totalSpent(); card na Dashboardu (samo ako ima podataka) + hero na tabu Novac
- [x] Migracija starog data.json: sideIncome/expenses → [] na loadu

## Otvoreni bugovi / TODO
- Nema poznatih bugova

## Arhitektura
- Single file: index.html (CSS + JS inline, bez dependencija)
- Storage: GitHub API → data.json u repu (primary), localStorage kao cache/offline
- Auth: GitHub OAuth token (gh auth token) ili PAT — localStorage keys: gh_pat, gh_owner
- SHA write: uvijek svježi GET prije PUT (u ghWrite())
- Encoding: TextEncoder/TextDecoder (UTF-8 safe, podržava čšžćđ)
- Auto-save: debounce 1000ms (scheduleSave())
- Offline fallback: localStorage key = 'ez_offline'

## Auto-setup flow (cross-device)
- URL format: `https://matijawork.github.io/emmezeta-zarada/#setup-OWNER_B64-TOKEN_B64`
- Base64url encode/decode: b64e/b64d funkcije u app-u
- App na init() čita hash → sprema u localStorage → briše hash → nastavlja normalno
- Laptop: pokrenuti `bash ~/Desktop/emmezeta-zarada/setup-laptop.sh`
- Mobitel: Postavke → "Generiraj setup link za mobitel" → kopiraj → otvori

## Data shape (data.json u GitHub repu)
```json
{
  "config": { "hourlyRate": 6.56, "ownerName": "Matija" },
  "shifts": [{ "id": "uuid", "date": "2026-06-15", "startTime": "07:00", "endTime": "15:00", "double": false }],
  "payments": [{ "id": "uuid", "date": "2026-06-22", "amount": 260.00, "weekKey": "2026-W26", "note": "" }],
  "sideIncome": [{ "id": "uuid", "date": "2026-06-21", "amount": 80.00, "source": "Baustela" }],
  "expenses": [{ "id": "uuid", "date": "2026-06-22", "amount": 15.00, "note": "Hrana" }]
}
```

## Izračuni
- Satnica: konfigurabilan (default 6.56 €/h)
- Dvostruka satnica: RUČNO po smjeni — shift.double === true → ×2 (nema više auto nedjelja/blagdani)
- shiftRate(sh) = baseRate × (sh.double ? 2 : 1); shiftEarned = sati × shiftRate
- MAXH = 8 → ako calcHours > 8 → crveno upozorenje na unosu (Matija ne smije >8h)
- Smjena preko ponoći: endMins <= startMins → endMins += 1440
- Sve $$: Math.round(x * 100) / 100
- Kumulativni dug = totalEarned() − totalPaid()  (SAMO Emmezeta — strana zarada/potrošnja NE diraju dug)
- Gotovina (svijet B, odvojeno): cashOnHand() = totalSide() − totalSpent()
- totalSide() = Σ sideIncome.amount; totalSpent() = Σ expenses.amount
- Potrošnja se oduzima SAMO od strane zarade (baustela itd.), nikad od Emmezeta isplata
- sideSources() = [...new Set] izvora iz sideIncome → chips (auto-update, pamti prošle izvore)
- ISO tjedan: "YYYY-WNN" format
- PRESETS: brze smjene (07–15, 08–16, 09–17, 14–22, 06–14) na unosu
- Maknuto: workDaysLeft brojač, Blagdani sekcija, auto ×2 badge-evi

## GitHub info
- Repo: https://github.com/matijawork/emmezeta-zarada
- GitHub Pages: https://matijawork.github.io/emmezeta-zarada/
- Branch: main, root /

## Kritično za sljedeću sesiju
- Satnica se mijenja u Postavkama → sprema u data.json config
- Sve kalkulacije su DERIVIRANE iz shifts — sprema se id/date/startTime/endTime/double
- weekKey u payments mora biti isoWeek(date) format (npr. "2026-W26")
- Ako GitHub sync ne radi → podaci lokalno u localStorage 'ez_offline', sync pri sljedećem init()
- LIVE SYNC (2026-06-24): refresh() auto-pulla data.json na focus/visibilitychange + setInterval 20s (startLive()). Guard: ne pulla ako S.syncing||saveTimer (lokalno spremanje) ni ako je INPUT/SELECT/TEXTAREA fokusiran. saveTimer=null nakon fire (inače guard blokira zauvijek). Cross-device near-realtime.
- iPhone: viewport-fit=cover + apple-mobile-web-app meta + safe-area-inset (main/toasts/nav). Inputi 16px → nema iOS zoom.
- classifier blokira komande s gh tokenima — korisnik mora sam pokrenuti u Terminal.app
- Tab Novac: inputi koriste readSide()/readExp() (DOM→state na oninput) BEZ re-rendera dok tipkaš (izbjegava gubljenje fokusa). Re-render samo na chip/Danas-Jučer tap i Dodaj/briši. Chip izvora šalje INDEX (mSrc(i)), ne string → sigurno za apostrofe. esc() escapea sav user tekst u HTML.

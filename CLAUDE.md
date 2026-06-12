# emmezeta-zarada — Claude Memory

## Status
- Zadnja sesija: 2026-06-12
- Faza: build

## Što je gotovo
- [x] Git setup + lokalni repo
- [x] index.html struktura i dizajn (black/purple theme)
- [x] Dnevni unos logika (datum, početak, kraj → auto izračun)
- [x] Tjedni izračuni (ISO tjedni, ponedjeljak–nedjelja)
- [x] Kumulativni dug logika (ukupno zarađeno − ukupno isplaćeno)
- [x] GitHub API sync (read/write sa debounce 1s)
- [x] Onboarding screen (PAT + GitHub username unos)
- [x] GitHub Pages deploy — https://matijawork.github.io/emmezeta-zarada/
- [x] Edge cases: smjena preko ponoći, nedjelja ×2, blagdan ×2, offline fallback

## Otvoreni bugovi / TODO
- Nema poznatih bugova
- GitHub username: matijawork
- GitHub Pages aktivan: https://matijawork.github.io/emmezeta-zarada/
- Za PAT u app onboardingu: kreiraj Fine-grained token na GitHub → Settings → Developer settings → Personal access tokens, Contents rw za repo emmezeta-zarada

## Arhitektura napomene
- Single file: index.html (CSS + JS inline, bez dependencija)
- Repo: public, GitHub Pages enabled
- Data: data.json u GitHub repu via API (GitHub Contents API)
- PAT: localStorage key = 'gh_pat', username = 'gh_owner' — NIKAD u repo
- SHA za write: uvijek dohvati svježi GET prije PUT-a (u ghWrite())
- Encoding: TextEncoder/TextDecoder za UTF-8 safe base64 (podržava čšžćđ u imenima)
- Auto-save: debounce 1000ms na svaku izmjenu (scheduleSave())
- Offline fallback: localStorage key = 'offline_data', sync pri sljedećem init()

## Izračuni
- Satnica: konfigurabilan u Postavkama (default 5.31 €/h)
- Nedjelja: automatski ×2 (isSun() via getDay() === 0)
- Blagdani: hardcoded Set: 2026-08-05 (Dan pobjede), 2026-08-15 (Velika Gospa)
- Smjena preko ponoći: ako endTime <= startTime → endMins += 1440 (calcHours())
- Sav novac: Math.round(x * 100) / 100 (money() helper)
- Kumulativni dug = totalEarned() − totalPaid() (nikad parcijalni tjedni)
- ISO tjedan: isoWeek() → "YYYY-WNN" format

## Data shape (data.json)
```json
{
  "config": { "hourlyRate": 5.31, "ownerName": "Matija" },
  "shifts": [{ "id": "uuid", "date": "2026-06-15", "startTime": "07:00", "endTime": "15:00" }],
  "payments": [{ "id": "uuid", "date": "2026-06-22", "amount": 260.00, "weekKey": "2026-W25", "note": "" }]
}
```

## Kritično za sljedeću sesiju
- Sve izračunate vrijednosti (sati, zarada, stopa) su DERIVIRANE, ne pohraniti u data.json
- weekKey u payments = isoWeek(date) — isti format kao u shifts
- GitHub Pages URL: https://{gh_owner}.github.io/emmezeta-zarada
- Datum range sezone: 2026-06-15 do 2026-09-30

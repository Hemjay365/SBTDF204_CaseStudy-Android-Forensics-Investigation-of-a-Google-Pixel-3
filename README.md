# SBT-DF205 Case 1: Android Forensics (Google Pixel 3, Android 10)

**Student:** Mary-Joy Adewole  |  **Reg number:** 2025/FWSD/11468  |  **Course:** SBT-DF205 Mobile and IoT Forensics, ICDFA
**Case reference:** SBT-DF205-C1  |  **Evidence:** Joshua Hickman, Android 10 Pixel 3 dataset, Digital Corpora (`Pixel 3.zip`, SHA-256 `ca6918ef8b20486b6a5ded15609ac51318f377829480f93be3ba15364a8aa00a`)

This package is a submission for the SBT-DF205 Case 1 lab. All times are UTC unless stated; raw timestamps are kept beside each conversion.

## What is in this package

| Item | What it is |
|---|---|
| `Report.pdf` | The examination report (6 pages of body, Appendix A screenshots, Appendix B full timeline) |
| `Evidence_Register.csv` | 64 evidence entries (EV-001 to EV-064): source path, record reference, size, SHA-256 |
| `Timeline.csv` | 30 events from 8 artefact families: UTC time, raw value, field, unit, description, evidence IDs |
| `Queries.sql` | The key SQL statements and non-SQL commands, with database and purpose for each |
| `Handling_Log.csv` | Evidence receipt, hashing, tool versions, processing steps, errors and corrections |
| `screenshots/` | The 12 captioned screenshots used as Figures 1 to 12 in Appendix A (cropped to the terminal window) |
| `supporting_evidence/command_output/` | Real text output of the queries and commands (e.g. `thread17_reconstruction.txt`, `dialer_vs_aosp.txt`, `exif_summary.txt`) |
| `supporting_evidence/media/` | The four images exchanged over WhatsApp and TextNow (hashes are in the register: EV-043, EV-044, EV-059, EV-060) |
| `supporting_evidence/Pixel3.zip.sha256` | The baseline hash file for the evidence archive |

## Not included (on purpose)

The 5.25 GB evidence archive, the extracted file system and the full database copies are not in the package. Only selected extracts and outputs are. Anyone can re-download the archive from the URL in the report, check it against the SHA-256 above, and re-run the statements in `Queries.sql` on the files named in `Evidence_Register.csv`.

## How to check the work

1. Download `Pixel 3.zip` and run `sha256sum "Pixel 3.zip"`; it must equal the hash above.
2. Pick any evidence ID in the report (for example EV-018, `mmssms.db`) and find its path and SHA-256 in `Evidence_Register.csv`.
3. Run the matching statement from `Queries.sql` on a copy of that file, keeping its `-wal` and `-shm` files with it.
4. Compare with the file of the same name in `supporting_evidence/command_output/`.

## Notes

- **Write-ahead logs matter.** `bugle_db` returns 36 messages with its WAL and 35 without; `wa.db` has no `wa_contacts` table without its WAL. All such databases were copied with their sidecars.
- **Duplicate register rows.** EV-040 to EV-042 repeat EV-037 to EV-039 (the same `location.db` files registered twice, identical hashes) and are annotated as such.
- **Corrections.** `Handling_Log.csv` is append-only. An early "image not found" entry is superseded by a later correction entry, and the first display of some token strings was discarded and logged. No secrets, tokens, keys or verification codes appear in this package.
- **Unresolved items are labelled.** Media times without a recorded offset (the video file, zone-less file times) and the Bluetooth `TimeCreated` value are marked unresolved. The conclusion is "unresolved", with alternative interpretations and the extra evidence needed.
- **Report-assembly rows.** The last six rows of `Handling_Log.csv` were added when the package was assembled (two note rows with a minute-level time, four dated at assembly).
- **Screenshots** are cropped to the terminal window so the text is legible; they were captured during the examination on the Kali VM.
- Evidence attribution: Joshua Hickman, Android 10 Pixel 3 dataset, Digital Corpora. Course reference: the supplied Android forensic investigation slides.

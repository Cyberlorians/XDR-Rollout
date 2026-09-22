# Reporting Comparison

This is a behavioral replacement map, not publication of the submitted source. A/G/S identify the original ASR, General, and Summary collections, numbered in executable-block order. All 35 original blocks were run separately in GCC High on September 22, 2026: 34 executed; G05 failed on missing `ConfigurationName`. Successful execution does not establish correct interpretation.

## Original to Rebuilt

| Original blocks | Replacement | Difference |
| --- | --- | --- |
| A01-A11, A14-A15 | [ASR events](ASR-Events.kql), filters in [README](README.md) | Consolidates 13 repetitive drilldowns; correct script action prefix, canonical GUID labels, raw fallback, explicit observed actions; does not discard investigation fields |
| A12 | [USB correlation](USB-Correlation.kql), `NearestOnly=false` | Preserves unmatched events; rejects empty drives; all candidates remain visible |
| A13 | [USB correlation](USB-Correlation.kql), default | Full event identity instead of repeating ReportId; unrounded nearest timestamp; preserves ties and unmatched events |
| G01 | [ASR events](ASR-Events.kql) | Replaces nonmatching CamelCase `has` fragments with GUID catalog and raw action fallback |
| G02 | [Daily activity](ASR-Daily-Activity.kql) | Retains raw action summary, adds daily grain, explicit warn bypass, event/device distinction |
| G03, G10 | [Readiness summary](Readiness-Summary.kql) plus [daily activity](ASR-Daily-Activity.kql) | Separates latest observed inventory from overlapping historical event populations |
| G04, G14 | [Weekly observations](Weekly-Observations.kql) | Removes duplicate; last observed onboarding within week rather than any-ever-in-week state; no migration-transition or stacked-total claim |
| G05, G13 | [Assessment detail](ASR-Assessments.kql) and [summary](ASR-Assessment-Summary.kql) | Removes unsupported historical configured-mode inference; current assessment evidence only. Historical posture requires retained snapshots |
| G06 | [Configuration discovery](Configuration-Discovery.kql) | Keeps KB discovery; latest per device/configuration before counts |
| G07, G11 | [Daily activity](ASR-Daily-Activity.kql) and [event detail](ASR-Events.kql) | Eliminates conflicting catalogs; separate recorded events and approximate device counts |
| G08 | [Daily activity](ASR-Daily-Activity.kql) | Raw GUID/action retained; explicit sampled file/process lists and warn category |
| G09 | [Assessment summary](ASR-Assessment-Summary.kql) | Separates applicability, compliance unknowns, stale assessments; no configured-mode claim |
| G12, G15 | [Combined device evidence](Device-Evidence-Summary.kql) and [configuration discovery](Configuration-Discovery.kql) | Removes duplicate, hostname joins, inferred modes, display-name pivots, first-observation migration dates, and vendor guesses |
| S01 | [Assessment detail](ASR-Assessments.kql) | Latest by DeviceId/configuration, applicability first, no mode guessing from Context text |
| S02 | [Assessment summary](ASR-Assessment-Summary.kql) | Reports assessment evidence, not configured policy counts |
| S03 | [Device readiness](Device-Readiness.kql) | Reuses repository AV telemetry, missing modes explicit, independent timestamps |
| S04 | [Combined device evidence](Device-Evidence-Summary.kql) | Missing assessments remain missing; no claim of full baseline from one block rule |
| S05 | [Readiness summary](Readiness-Summary.kql) plus [assessment summary](ASR-Assessment-Summary.kql) | Replaces invented phase labels with factual evidence dimensions; EDR block is not Active |

## Compared with Existing Repository Queries

| Existing source | Reuse / difference |
| --- | --- |
| AV-mode inventory | Same mode codes/source; original returns TVM-observed devices in seven days. Rebuilt reports start from 30-day inventory, retain missing mode records, filter merged-away inventory, and expose source recency separately |
| Intune ASR generator | Canonical GUID catalog cross-checked and reused conceptually. Remains optional configured-policy context; not copied or relabeled as effective-device state |
| Change-auditing examples | Complementary history; not mixed into native hunting queries that lack their Sentinel ingestion prerequisites |

## Reproduced Differences

- Live KB lookup identifies scid-2011 as definition updates, scid-2012 as real-time protection, and scid-2013 as PUA protection. They are not Passive/Active/EDR-block mode identifiers.
- One of eight live inventory devices was `Unknown` in S03 but `Passive` in reported AV-mode telemetry. This comparison does not independently certify the endpoint's operating state.
- Synthetic canonical JavaScript download event: original A04 returned zero rows; rebuilt detail includes it.
- Synthetic Office-child GUID: original G07 labels it email/webmail; rebuilt detail labels it Office child processes.
- Synthetic A12 retained only seven of ten USB event identities and falsely matched empty drives. Rebuilt all-candidate and nearest views retain all ten and reject blank drives.
- Synthetic A13 collapsed all matching events sharing ReportId 7 into one row. Rebuilt nearest view returns 11 rows for ten event identities because one event has two equally nearest mounts.

Original files remain private and unchanged. The public pack contains generic recreated queries, synthetic fixtures, and aggregate validation evidence only.
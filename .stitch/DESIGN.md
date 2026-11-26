# Chiraag e Azaa — Design System (`.stitch/DESIGN.md`)

## 1. Visual World & Surface Mode
- **Surface Mode:** `Operate` — daily spiritual devotional library & Holy Quran reader for devotees, Noha Khwans, and Zakirs.
- **Atmosphere:** Serene emerald sanctuary anchored by crisp neutral surfaces, warm burnished gold borders/accents for sacred milestones, and full calligraphic clarity (`ScheherazadeNew`) for Arabic and Urdu scripts.
- **Platform:** iOS-first with floating Liquid Glass bottom navigation capsule + detached circular Search action (adapts to `NavigationRail` on iPad ≥ 720pt).

## 2. Calibrated Color Roles (WCAG AA Verified)
| Role | Hex | Usage | Contrast vs Canvas/Card |
|------|-----|-------|--------------------------|
| Canvas (`bg`) | `#F3F5F4` | App background canvas | — |
| Elevated Card (`card`) | `#FFFFFF` | Primary cards & collection rows | — |
| Deep Emerald (`hero`) | `#134A1F` | Hero sanctuary banner | White text `> 9.5:1` |
| Primary Ink (`textPrimary`) | `#141816` | Headlines, card titles | `17.5:1` on card |
| Secondary Ink (`textSecondary`) | `#525C56` | Subtitles, metadata | `6.7:1` on card |
| Primary Accent (`accent`) | `#1A5C28` | Active tabs, primary actions, badges | `8.1:1` on card / white |
| Accent Soft (`accentSoft`) | `#E8F5EC` | Icon wells, count chips | `#144A20` text `9.2:1` |
| Sacred Gold (`gold`) | `#9A7B2C` | Borders, icons, callout trim | `3.9:1` (large/icons) |
| Sacred Gold Text (`goldInk`) | `#7A5A0F` | Small gold-tinted body copy | `6.0:1` on card |
| Gold Soft (`goldSoft`) | `#FDF6E2` | Hijri crescent tile, Quran highlight | — |
| Hairline (`separator`) | `rgba(0,0,0,0.08)` | 1px card & row borders | — |

## 3. Typography & Spacing Scale
- **UI Typography:** `NotoSansArabic` / system sans; clear scale (`20px` greeting, `16px` section headers, `14px` card titles, `12px` metadata, no truncation).
- **Arabic & Urdu Script:** `ScheherazadeNew` (`letterSpacing: 0`, `lineHeight: 1.4–2.0`).
- **Spacing:** `4 / 8 / 12 / 16 / 20 / 24 px`; tight intra-card spacing (`6–8px`), clear inter-section spacing (`18–20px`).
- **Radii:** `12px` inner controls, `16–18px` cards, `28–30px` floating capsule nav.
- **Craft Rules:** Zero emoji stand-ins for icons, zero nested boxes inside cards, zero duplicated Search bars on Home when bottom Search button is docked.

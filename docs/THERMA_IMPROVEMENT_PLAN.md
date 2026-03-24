# Therma Improvement Plan

This note maps the most relevant skill workflows to the current Therma codebase.

## Recommended Skills

| Skill | Use In Therma | Immediate Value |
| --- | --- | --- |
| `frontend-design` | Refine Dashboard, Settings, Menu Bar, Alerts, About layouts | Better visual hierarchy, spacing, and card composition |
| `theme-factory` | Unify colors, typography, and component styling across screens | More consistent product feel |
| `doc-coauthoring` | Write refactor specs for refresh coordination, updater hardening, and Settings decomposition | Cleaner execution on larger changes |
| `brand-guidelines` | Polish brand voice, screenshots, store assets, and identity | More professional product presentation |
| `mcp-builder` | Add future integrations or tooling around Therma | Useful only when expanding beyond the app itself |

## Apply vs Skip

| Skill | If We Use It | If We Skip It |
| --- | --- | --- |
| `frontend-design` | UI decisions stay intentional and polished | UI can work but feel uneven or improvised |
| `theme-factory` | Screens stay visually aligned | Different pages can drift into different styles |
| `doc-coauthoring` | Refactors get a clear plan and lower regression risk | Bigger changes are easier to lose scope on |
| `brand-guidelines` | Therma looks more productized outside the app | Branding remains functional but generic |
| `mcp-builder` | Future integrations have a solid starting point | No impact unless integrations become a goal |

## Recommended Order

1. Use `doc-coauthoring` to define the performance and maintainability roadmap.
2. Use `frontend-design` to improve the highest-traffic screens.
3. Use `theme-factory` to lock those UI changes into one visual system.
4. Use `brand-guidelines` for outward-facing polish.
5. Use `mcp-builder` only if the product expands into integrations.

## Current Technical Priorities

1. Repair the stale test suite.
2. Consolidate overlapping timers and refresh loops.
3. Reduce repeated process scanning cost.
4. Break up oversized Settings files into smaller view modules.
5. Harden the updater flow.

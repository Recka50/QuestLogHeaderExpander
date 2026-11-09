# Changelog

All notable changes to Quest Log Header Expander are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/) (pre-1.0 while the game is in beta).

## [1.1.1] - 2026-11-09
 
### Changed
 
- Swapped location of Untrack and expand/collapse button
- Swapped buttons to checkboxes

## [1.1.0] - 2026-11-09
 
### Added
 
- New Feature - Optional `Untrack` button that stops tracking every quest at once. Off by default; enable it under *Options → AddOns → Quest Log Header Expander*.
- New Feature - Optional `Track` button for quest headers that tracks/untracks all quests for a zone.
- Added `qlhe` slash commands. (Use `/qlhe help` to show commands).
- One-time welcome popup pointing to the new options and the `/qlhe` command.

## [1.0.0] - 2026-11-08

### Fixed

- Resolved bug where `+ All` / `- All` buttons moved off of quest log when highlighting quest markers on map.

## [0.5.0] - 2026-10-01

### Added

- Option to remember previous quest log state. Keeps state of the quest log headers from when the map is closed.

## [0.4.1] - 2026-09-31

First public release.

### Added

- `+ All` / `- All` button next to the quest counter that expands or collapses every zone header at once.
- Startup behaviour applied each time the map opens: Default (Blizzard), Always collapsed, Always expanded
- Right-click menu on the button for switching modes.
- Options panel under *Options → AddOns → Quest Log Header Expander*.
- Quest log search box is resized so the button fits alongside it.

### Changed

- Quest log scans are coalesced to once per frame and skipped while the quest log is hidden, reducing garbage and CPU use.

### Fixed

- Search box resize now retries until the box exists, since it isn't created until the map is first opened.
- Duplicate `OnShow` hooks on the search box are no longer added repeatedly.

[0.4.1]: https://github.com/Recka50/QuestLogHeaderExpander/releases/tag/v0.4.1
[0.5.0]: https://github.com/Recka50/QuestLogHeaderExpander/releases/tag/v0.5.0
[1.0.0]: https://github.com/Recka50/QuestLogHeaderExpander/releases/tag/v1.0.0
[1.1.0]: https://github.com/Recka50/QuestLogHeaderExpander/releases/tag/v1.1.0
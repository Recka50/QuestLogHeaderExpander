# Changelog

All notable changes to Quest Log Header Expander are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/) (pre-1.0 while the game is in beta).


## [0.5.0] - 2026-10-01

### Added

- Option to remember previous quest log state. Keeps state of the quest log headers from when the map is closed.

### Changed

-

### Fixed

-

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

[0.4.1]: https://gitea.recka.tech/bepis/QuestLogHeaderExpander/releases/tag/v0.4
[0.5.0]: https://gitea.recka.tech/bepis/QuestLogHeaderExpander/releases/tag/v0.5
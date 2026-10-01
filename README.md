# Quest Log Header Expander

A small World of Warcraft addon that adds an **expand/collapse all** button to the quest log, so you can open or close every zone header in one click instead of only getting the zone you're currently in.

Built for **World of Warcraft Forever** using the retail UI API. Interface version `16001`.

<!-- Add screenshots here, e.g.:
![Quest log with the +/- All button](docs/button.png)
-->

## Features

- **Toggle button** next to the quest counter: `+ All` expands every zone header, `- All` collapses them.
- **Configurable startup behaviour**, applied each time the map/quest log opens:
  - **Default**: Blizzard's standard behaviour (only the current zone is expanded)
  - **Always collapsed**
  - **Always expanded**
- **Right-click the button** for a quick context menu to change the mode.
- **Options panel** under *Options → AddOns → Quest Log Header Expander* with the same setting.
- Resizes the quest log search box so the button fits alongside it.

## Installation

1. Download the latest release from the [releases](https://github.com/Recka50/QuestLogHeaderExpander/releases) page. Don't use "Source code (zip)", as it has the wrong folder name.
2. Extract it into your `Interface/AddOns/` folder so you end up with `Interface/AddOns/QuestLogHeaderExpander/`.
3. Fully restart the game (Required for first-time run).

### Or

1. Download or clone this repository.
2. Make sure the folder is named `QuestLogHeaderExpander` (it must match the `.toc` file name).
3. Extract it into your `Interface/AddOns/` folder so you end up with `Interface/AddOns/QuestLogHeaderExpander/`.
4. Fully restart the game (Required for first-time run).

Your folder should look like this:

```
QuestLogHeaderExpander/
├── QuestLogHeaderExpander.toc
├── QuestLogHeaderExpander.lua
└── README.md
```

## Usage

| Action | Result |
| --- | --- |
| Left-click the button | Expand or collapse all zone headers |
| Right-click the button | Open the mode context menu |
| Options → AddOns → Quest Log Header Expander | Choose the startup mode from a dropdown |


## Configuration

Settings are stored per account in the `QuestLogHeaderExpanderDB` saved variable:

| Key | Values | Description |
| --- | --- | --- |
| `mode` | `default`, `collapsed`, `expanded` | Default quest log header behaviour when the map opens |

## Troubleshooting

**Search box isn't resized / button overlaps it**
The search box is created when the map is first opened. The addon retries on quest log updates until it exists, so open the map once and it should adjust.

**Settings don't persist**
Make sure that you have fully logged out/in or restarted your game.

## Contributing

Issues and pull requests are welcome. When reporting a bug, include your game build, the addon version, and any Lua error text.

## License

Released under the [MIT License](LICENSE).
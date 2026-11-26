# Quest Log Header Expander

A small World of Warcraft addon that adds an **expand/collapse all** button to the quest log and (optionally) your profession windows, so you can open or close every header in one click.

Built for **World of Warcraft Forever** using the retail UI API. Interface version `16001`.

## Features

- **Toggle button** next to the quest counter: `+ All` expands every zone header, `- All` collapses them.
- **Configurable startup behaviour**, applied each time the map/quest log opens:
  - **Default**: Blizzard's standard behaviour (only the current zone is expanded)
  - **Always collapsed**
  - **Always expanded**
  - **Remember previous state**
- **Right-click the button** for a quick context menu to change the mode.
- **Options panel** under *Options → AddOns → Quest Log Header Expander* with the same setting.
- Resizes the quest log search box so the button fits alongside it.
- **Profession windows** (optional, off by default): the same `+ All` / `- All` button next to the recipe search box, with its own startup behaviour (Default, Always collapsed, Always expanded, Remember previous state, remembered per profession) and right-click menu.

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
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Usage

| Action | Result |
| --- | --- |
| Left-click the button | Expand or collapse all zone headers |
| Right-click the button | Open the mode context menu |
| Options → AddOns → Quest Log Header Expander → Show button on profession windows | Add the expand/collapse button to profession windows |
| `/qlhe toggleprofession` | Toggle the profession window button |
| Options → AddOns → Quest Log Header Expander | Choose the startup mode from a dropdown |


## Configuration

Settings are stored per account in the `QuestLogHeaderExpanderDB` saved variable:

| Key | Values | Description |
| --- | --- | --- |
| `mode` | `default`, `collapsed`, `expanded`, `remember` | Quest log header behaviour when the map opens |
| `showProfession` | `true`, `false` | Show the expand/collapse button on profession windows |
| `professionMode` | `default`, `collapsed`, `expanded`, `remember` | Recipe header behaviour when a profession window opens |

## Troubleshooting

**Search box isn't resized / button overlaps it**
The search box is created when the map is first opened. The addon retries on quest log updates until it exists, so open the map once and it should adjust.

**The profession button doesn't appear**
It's off by default. Enable it under *Options → AddOns → Quest Log Header Expander*, then reopen the profession window. If it still doesn't show or work, run `/qlhe profdebug` with the profession window open and include the output in your bug report.

**Settings don't persist**
Make sure that you have fully logged out/in or restarted your game.

## Contributing

Issues and pull requests are welcome. When reporting a bug, include your game build, the addon version, and any Lua error text.

## License

Released under the [MIT License](LICENSE).
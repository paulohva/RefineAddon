# Contributing to Refine

Thanks for helping out! Bug reports, ideas and pull requests are all welcome.

## Reporting a bug

Open an issue and include:

- what you did, what you expected, and what happened instead;
- the output of `/refine diag`;
- the full Lua error text, if there was one ([BugSack](https://www.curseforge.com/wow/addons/bugsack) makes this easy);
- your game version (shown by `/refine diag`).

## Development setup

1. Clone the repository anywhere you like.
2. Link the folder into the game, so `/reload` picks up your changes. From a Command Prompt:

   ```bat
   mklink /J "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\Refine" "C:\path\to\your\clone"
   ```

   The link must be called `Refine` (the addon's name), whatever your clone's folder is called.

   On macOS, use `ln -s` into `/Applications/World of Warcraft/_forever_/Interface/AddOns/`.

3. Log in, make changes, and type `/reload`. `/refine debug` prints what the addon is doing.

## Code layout

| File | Purpose |
|---|---|
| `Core.lua` | Namespace, secret-safe helpers, event dispatcher, saved variables |
| `Locales.lua` | Translations (`ns.L`) |
| `Analyze.lua` | The comparison between the spellbook and the bars (no game API, easy to test) |
| `Spellbook.lua` | Reads the spellbook: every spell, all its ranks together |
| `Bars.lua` | Reads the action slots (all bars and pages, and macros) |
| `Update.lua` | Scans, keeps the ignored spells, and puts the highest ranks on the bars |
| `UI/SpellbookButton.lua` | The refresh button in the spellbook and its tooltip |
| `UI/IgnoreWindow.lua`, `UI/IgnoreRow.xml` | The window to choose the spells to ignore |
| `Trainer.lua` | The chat line after the trainer |
| `Slash.lua` | `/refine` commands and `/refine diag` |
| `Media/Icon.tga` | The addon's icon in the game's AddOns list (64×64, 32-bit TGA) |
| `Media/Portrait.tga` | The ignored spells window's portrait: the logo drawn smaller, as the portrait zooms in (256×256) |

## Guidelines

- **Indentation:** use tabs in Lua, matching the existing code.
- **Language:** write player-facing text in English and wrap it in `L["..."]`, then add the
  translation to each language block in `Locales.lua`. Spell names and ranks come from the game,
  already translated. Debug and `/refine diag` output stays in English.
- **Adding a language:** copy the `ptBR` block in `Locales.lua`, change the locale code
  (`deDE`, `frFR`, `esES`, ...) and translate the right-hand side.
- **Secret values:** WoW: Forever restricts addons the same way as Midnight. Game values can be
  *secret*. Read game values through `ns.Safe` (`Safe.Call`, `Safe.CallAll`, `Safe.Field`).
- **Taint:** don't hook or modify Blizzard frames. The spellbook button is the addon's own frame,
  only anchored to the spellbook.
- **One change per pull request**, with a short description of what it does and how you tested it
  in game.
- **Changelog:** add a line under *Unreleased* in `CHANGELOG.md`.

## Releasing (maintainers)

1. In the release pull request, move the *Unreleased* changelog entries under a new `## X.Y.Z` heading.
2. Merging it runs `.github/workflows/release.yml`: it builds `Refine-vX.Y.Z.zip`
   (without the files listed under `ignore` in `.pkgmeta`, and with `@project-version@` in the `.toc`
   replaced by the version), uploads it to CurseForge and creates the GitHub release `vX.Y.Z`.
   It needs the repository secret `CF_API_KEY` and the `X-Curse-Project-ID` line in the `.toc`.

By contributing, you agree that your contributions are licensed under the project's
[MIT License](LICENSE).

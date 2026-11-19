# Refine

**Keep your skills up to date, in World of Warcraft: Forever.**

When you learn a new rank at the trainer, your action bars keep the old one. Refine adds a small
refresh button to the spellbook that puts the highest rank you know on your bars, in one click.

*Refine was called SpellbookRefresh up to version 1.0.0.*

---

## Features

- **One small button in the spellbook**, on the line of the page title. It shows a golden check
  when every spell on your bars is at its highest rank, and an **orange** refresh symbol, with a
  count, when some can be updated. Click it and they are.
- **Lower ranks you keep on purpose stay.** If a spell is on your bars more than once, in different
  ranks, only the highest one is updated. A lower rank you keep to save mana stays where it is.
- **Spells you haven't placed yet.** A small (i) on the button means some of your class spells
  aren't on any bar; its tooltip lists them. Right-click the button to ignore the ones you don't
  want there.
- **A reminder after the trainer.** One chat line when spells on your bars got a new rank.
- **Every bar and page**, including the stance and form bars. Macros and items are never changed.

## Languages

Refine follows your game client's language. It includes **English** and **Português (Brasil)**;
spell names and ranks always come from the game. Translations are welcome; see
[CONTRIBUTING.md](CONTRIBUTING.md).

## Installation

- **CurseForge:** install *Refine* with the CurseForge app.
- **Manual:**
  1. Download the latest release zip.
  2. Extract it into `World of Warcraft\_forever_\Interface\AddOns\`. You should end up with
     `...\AddOns\Refine\Refine.toc`.
  3. Restart the game, or type `/reload` if you're already logged in.

If you had SpellbookRefresh, remove its folder (`...\AddOns\SpellbookRefresh`): Refine replaces it.

## Usage

Open the spellbook (**P**). The button is at the top right of the page, on the line of the title
("General", "Frost"...).

| Command | What it does |
|---|---|
| `/refine update` | Update your bars (the same as the button) |
| `/refine ignore <spell>` | Don't list a spell that isn't on your bars, e.g. `/refine ignore Slow Fall` |
| `/refine unignore <spell>` | List an ignored spell again |
| `/refine ignored` | Show the ignored spells |
| `/refine trainer` | Turn the chat line after the trainer on or off |
| `/refine diag` | Check what your game client allows (for bug reports) |

## How it works

The spellbook knows every rank you've learned, even when it hides the lower ones. Refine reads it,
looks at every action slot, and compares, for each spell, the highest rank on your bars with the
highest rank you know. Updating picks up the spell from the spellbook and drops it on the slot, the
same as dragging it there yourself.

### Limitations

- **Out of combat only.** The game doesn't let addons change your action bars in combat; the button
  is greyed out until combat ends.
- **Macros aren't changed.** They count as "on your bars", so a spell you only use in a macro isn't
  listed as missing.
- **Pet bar.** Pet spells aren't changed.

## Contributing

Bug reports, ideas and pull requests are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) to get
started. When reporting a bug, please include the output of `/refine diag` and any Lua error text.

## Credits

Refine was developed with the help of AI tools.

## License

[MIT](LICENSE). You're free to use, modify and share this addon. Please keep the copyright notice.

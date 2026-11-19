# Changelog

All notable changes to Refine (called SpellbookRefresh up to 1.0.0) are listed here.

## Unreleased

## 1.2.0

- The button only shows when there's something to do: the orange refresh symbol with a count when
  spells can be updated, or the golden check with the (i) when your bars are up to date but some
  class spells aren't on any bar. When there's nothing left, it disappears.
- A small window to choose the spells to ignore: the class spells that aren't on any bar, each
  with a check box. Right-click the button or type `/refine ignored` to open it, so it works even
  while the button is away. It replaces the right-click menu.

## 1.1.0

- New name: SpellbookRefresh is now **Refine**. Its folder is now `Refine` and its command
  `/refine`; if you had SpellbookRefresh, remove its old folder. Ignored spells start over.
- A new button: a small square button at the top right of the spellbook page, on the line of the
  title. It shows a golden check when your bars are up to date, and an orange refresh symbol, with
  a count, when spells can be updated; the (i) shows in its corner.

## 1.0.0

- First release: a button in the spellbook that puts the highest rank of your spells on your action
  bars. It's green when every spell on your bars is at its highest rank, and orange, with a count,
  when some can be updated.
- When a spell is on your bars in more than one rank, only the highest one is updated; lower ranks
  you keep on purpose stay.
- A small (i) on the button while some of your class spells aren't on any bar. Its tooltip lists
  them; right-click the button to ignore them.
- One chat line after the trainer when spells on your bars got a new rank (`/sbr trainer` turns it
  off).
- English and Português (Brasil).

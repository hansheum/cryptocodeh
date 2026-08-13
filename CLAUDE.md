# cryptocodeh — submodule notes

Cross-project submodule (my fork of Martijn's cryptocode/cryptocrakz), added
to projects as `git submodule add https://github.com/hansheum/cryptocodeh.git
cryptocodeh`. Changes here propagate to every consuming project — keep them
general, not project-specific.

## Files
- `cryptocodeh.tex` — main macros (`\input` directly, e.g. `\input{../cryptocodeh/cryptocodeh}`).
- `cryptocrakz.tex` — companion macros.
- `texfrog.sty` — local copy of TeXFrog (game-hopping proof management).
  Loaded as a package (options go through `\usepackage`, so it can't be
  `\input`): `\usepackage[package=cryptocode, strikeout]{../cryptocodeh/texfrog}`.
  Path-qualified name works because `\usepackage` resolves the relative path
  against the main file's directory.

## texfrog.sty: `strikeout` package option (2026-07-21)

Goal: `\usepackage[package=cryptocode, strikeout]{texfrog}` makes
`\tfrendergame[diff=G0]{src}{G1}` also render lines that are in the diff
target (G0) but NOT in the current game (G1), struck out — in addition to
the existing blue highlight on added lines.

How diff rendering works:
- Recording pass (mode 1): source expanded for the diff-target game inside a
  discarded vbox; every `\tfonly` increments `\g__tf_pos_int` and positions
  whose tags match are recorded in `\g__tf_recorded_prop`.
- Render pass (mode 2): positions active in current game but absent from
  `\g__tf_recorded_prop` get wrapped in `\tfchanged`. Positions NOT active in
  the current game are silently suppressed — the branch strikeout changes.

Implementation:
1. l3keys option: `strikeout .bool_gset:N = \g__tf_strikeout_bool`,
   `.default:n = true`, `.initial:n = false`.
2. After `\ProcessKeysOptions`: `\bool_if:NT \g__tf_strikeout_bool
   { \RequirePackage[normalem]{ulem} }`.
3. `\providecommand{\tfremoved}[1]` — gray (`black!50`) + `\sout`; math-mode
   content wrapped `\hbox{...\sout{$\displaystyle#1$}}` (mirrors `\tfchanged`'s
   `\ifmmode` split; cryptocode bodies are math).
4. `\__tf_wrap_removed:n` = `\__tf_do_wrap:nnN {#1} {} \tfremoved` — reuses
   existing trailing-`\\` / leading-`\item`/`\State` extraction.
5. In `\__tf_only_render:nn` false branch (game not in tags): if strikeout
   bool AND position is in `\g__tf_recorded_prop` → `\__tf_wrap_removed:n`.
   Needs variant `\cs_generate_variant:Nn \prop_if_in:NnT { NeT }`.
6. Starred `\tfonly*` stays undecorated (clean) — star means "no decoration",
   so removed starred lines stay suppressed.

Status: DONE and verified. Enable via `\usepackage[package=cryptocode,
strikeout]{texfrog}`; appearance redefinable via
`\renewcommand{\tfremoved}[1]{...}`.

### strikeout follow-up — force gray over inner colors

`\tfremovedstyle` (user-facing, redefinable) sets the gray AND locally no-ops
`\color`/`\textcolor`, so inner color markup like `\red{...}`
(= `\textcolor{red}` from cryptocodeh.tex:60, used for bad events) is forced
gray inside removed lines. Redefinitions are local to the group/box
`\tfremoved` opens; normal renders keep their colors.
Note: the Python/HTML pipeline (texfrog/filter.py upstream) is NOT touched —
strikeout is LaTeX-side only.

## texfrog.sty: figure-mode ranges + compressed game comments (2026-07-21)

Goal: (a) `\tfrenderfigure{defprog}{G0-G4}` accepts ranges in the games
list; (b) figure-mode line comments compress contiguous runs (in figure-list
order) to "G1-G4" instead of "G1,G2,G3,G4".

Implementation:
1. `\__tf_split_on_hyphen:nnN`: on valid range, fill ordered
   `\l__tf_range_labels_clist`; `\__tf_resolve_single_tag:n` maps that clist
   into the prop.
2. `\__tf_set_figure_games:n`: expands ranges into
   `\g__tf_figure_games_clist` (used by `\tfrenderfigure` after source
   activation, which the range parser needs for the games seq).
3. `\__tf_only_figure:nn`: collect 1-based match indices in
   `\l__tf_match_idx_seq`; `\__tf_build_gamelist_label:` compresses
   consecutive-index runs (len >= 2 -> "first-last") via `\__tf_emit_run:`.
   Contiguity is relative to the FIGURE list order, not the global games seq.

Status: DONE and verified. Runs of length 2 also compress ("G2-G3"). Range
separator is the user-facing `\tfgamerangesep` (default `\,\mbox{--}\,` —
thin-spaced en-dash, boxed so the ligature works even if the comment lands in
math mode; user prefers spacing around the dash over the Chicago-style
closed-up range dash).

## texfrog.sty: strict validation of game references (2026-07-22)

Goal: unknown game references fail compilation instead of silently
no-matching. Replaces the old "unknown labels kept literally, never match"
behavior (which turned a stray `\tfrenderfigure{defprog}{G0-G6}` — G6 not
defined — into a downstream `Missing $` error far from the real cause).

Implementation:
- `\msg_new:nnn { texfrog } { unknown-game }` + helper
  `\__tf_check_label_known:n`: looks the label up in `\g__tf_games_seq` (via
  `\__tf_find_index:nN`) and raises `\msg_error:nnee` if absent, naming the
  offending reference and the known games.
- Wired into the three reference sites, all after source activation (so the
  games seq is live):
  1. `\tfonly{...}` tags — `\__tf_resolve_single_tag:n` literal branch.
  2. Figure lists — `\__tf_set_figure_games:n` literal branch.
  3. `\tfrendergame` — the rendered game and the `diff=` target (the latter
     e-expanded, `\exp_args:Ne`, since it may arrive as a tl var).

One check on the literal-label path covers BOTH failure modes: a plain
unknown label AND a malformed range whose endpoint no longer exists — a bad
range fails to parse and falls through to exactly that literal path. Valid
ranges take the range branch and are already endpoint-validated by
`\__tf_find_index` during parsing, so they never hit the check.

Status: DONE and verified — full doc compiles clean; reintroducing `G0-G6`
fails with exit 1 and a clear `Package texfrog Error: Unknown game 'G0-G6'
referenced ... Known games are: G0, G1, G2, G3, G4, G5.`

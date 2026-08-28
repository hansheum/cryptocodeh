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
- `texmf/` — a minimal TEXMF tree carrying the Type1 build of JetBrains Mono
  used by `\monofont` (20 files, ~700 KB). See below; consuming projects must
  point kpathsea at it.
- `install-fonts.sh` — one-shot installer for collaborators who do not build
  with latexmk. Detects OS and TeX distribution, registers (MiKTeX) or copies
  (TeX Live) the tree, then compiles a test document to prove it worked.
  Tested on macOS/TeX Live, including the failure path; bash 3.2 compatible.
- `install-fonts.ps1` — native-Windows-PowerShell companion. **Unverified**:
  written with no Windows machine available, never executed or parsed. Its
  header carries the two-command manual fallback.

## `\monofont{...}` and the bundled JetBrains Mono (2026-08-20)

`\monofont{0101}` sets its argument in JetBrains Mono — far more distinct from
body text than `\texttt` (slashed zero, serifed one), which is the point: bit
strings should not be mistakable for ordinary numerals. `\monofontshape` is the
bare font switch if a whole block needs it; `\monofontscale` (default `0.87`)
brings the font down to the body x-height.

**Upright is pinned.** llncs theorem/definition/lemma bodies set `\itshape`,
and because the family has a real italic cut, `\monofont` was picking it up and
slanting bit strings — in math too, since `\text` inherits the outer text font.
`\monofontshape` therefore forces `\fontshape{\updefault}`. Series is left
inherited, so it still goes bold in headings; `\monofontshape\itshape` still
reaches the italic cut for anyone who deliberately wants it. Verified
layout-neutral on the full QROM document (105 pages either way).

**Text and math render identically.** `\monofont` wraps its argument in
`\text{}`, which in text mode is `\mbox` and in math mode re-selects the font
at `\tf@size` — the same box either way. Verified: identical width, height and
depth to 5 decimal places, and pixel-identical 600 dpi renderings of
`\monofont{0101gjQ}` vs `$\monofont{0101gjQ}$`, both plain and inside
`\textbf` (with a positive control confirming the comparison can detect a
difference). Inside sub/superscripts it scales down with the math style, which
is the desired behaviour, not an inconsistency.

**Why a bundled TEXMF tree.** pdflatex cannot use the Nerd Font TTFs directly —
only XeLaTeX/LuaLaTeX can. `texmf/` holds a Type1 build generated with
`autoinst` from the OTFs in TeX Live's `jetbrainsmono-otf` package (the ASCII
glyphs are identical: the NL/Nerd patches only drop ligatures and add icons):

```bash
cp $(kpsewhich --var-value=TEXMFDIST)/fonts/opentype/SIL/jetbrainsmono-otf/JetBrainsMono-{Regular,Bold,Italic,BoldItalic}.otf .
autoinst -encoding=T1 -typewriter -nots1 -nooldstyle -noproportional \
         -nosmallcaps -noswash -notitling -nosuperiors -noinferiors \
         -nofractions -noornaments JetBrainsMono-*.otf
```

`cryptocodeh.tex` declares the font shapes itself and calls
`\pdfmapfile{+JetBrainsMono.map}`, so no `updmap` run is needed. The `.fd` is
shipped lowercased (`t1jetbrainsmono-tlf.fd`) because NFSS looks `.fd` files up
in lowercase, which matters on case-sensitive filesystems.

**Consuming projects must set the search path.** kpathsea only searches the
project root non-recursively, so it will not find `cryptocodeh/texmf/` on its
own. Cheapest fix is a `.latexmkrc` in the project root:

```perl
$ENV{'TEXMFAUXTREES'} = './cryptocodeh/texmf,';   # trailing comma required
```

For non-latexmk builds (TeXShop, a plain `pdflatex` invocation, CI), export
`TEXMFAUXTREES=./cryptocodeh/texmf,` instead. Without it the build dies on a
missing `JetBrainsMono-Regular-tlf-t1` font — that error means the path is
unset, not that the files are missing.

## Bit-string notation: `\bits`, `\nil`, `\bin`, … (2026-08-28)

Moved here from the QROM-toolbox project, so every consumer gets one spelling
of the notation instead of a per-project `\renewcommand`. `\monofont` is the
font-level entry point; `\bits{0101}` is the notation-level one, and on top of
it sit the single bits `\nil` / `\one` and their alphabet `\bin` (a
`\renewcommand` over cryptocode's plain `\{0,1\}`), plus the dual-alphabet
(Hadamard) variants `\hnil` = |+>, `\hone` = |->, `\hbin`.

The notion parameter `\bits` = `\beta` that used to sit in the 2.8 Crypto
Notions block is **gone**, since the bit-string macro took the name. Nothing
that loads this file was using it: the projects that write `\bits` in the
`\beta` sense (multiuserhybrid and its siblings — MultiUser, WeakerSOA,
MultiInstance, thesis) load the frozen `cryptocodex.tex` in their own repo, not
this submodule, and each already defines `\bits` locally in its `*-latex.tex`.
If one of them is ever migrated onto cryptocodeh, flip that local
`\newcommand{\bits}{\beta}` to `\renewcommand` — as a `\newcommand` it will
clash with the definition here.

## Standard gates: `\Xgate`, `\Hgate`, … (2026-08-28)

Moved here from QROM-toolbox's `qrot-latex.tex` for the same reason as the
bit-string notation above: pqSimstar had copied quantum pseudocode across and
hit `Undefined control sequence \Hgate`, because the gates were project-local
to the toolbox.

Shared here: `\Xgate`, `\Ygate`, `\Zgate`, `\Hgate`, `\Sgate`, `\Tgate`,
`\CXgate`, `\CCXgate`, `\CZgate`, `\SWAPgate`, `\CSWAPgate` – all one-liners
over `\unitary`, so they inherit its shape (`\mathrm` here; the toolbox's old
`\mathsf` version was already commented out, so nothing re-renders).

Deliberately NOT moved, and still in `qrot-latex.tex`: `\eCXgate`
(`\CXgate_\emptystring`), `\hCZgate` (hatted control), `\SORTgate` – derived
or non-standard, and specific to the toolbox's development. They keep working
there since they build on the primitives defined here.

Consumers load `cryptocodeh.tex` before their own `*-latex.tex`, so a project
that wants a different shape can still `\renewcommand` locally.

## quantikz2 namespace (2026-08-13)

`cryptocrakz.tex` loads the quantikz2 tikzlibrary, which claims `\ctrl`,
`\permute`, and `\swap`. Policy: quantikz owns those names outright, no
`\let` juggling — cryptocodeh's macros are `\ctrlU` (controlled-unitary
operator $\mathsf{C}(\cdot:\cdot)$), `\permutereg`, and `\swapreg`.

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

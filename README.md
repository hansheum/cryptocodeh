# cryptocodeh
My version of Martijn's cryptocodex and cryptocrakz

# Usage
Add to project as submodule: `git submodule add https://github.com/hansheum/cryptocodeh.git cryptocodeh`

# Fonts

The submodule ships `texmf/`, a small Type1 build of JetBrains Mono behind the
`\monofont{...}` macro (pdflatex cannot use the Nerd Font TTFs directly).
kpathsea does not search the submodule on its own, so one of these is needed:

**If you build with latexmk** (including `latexmk -pvc`), nothing to do — the
consuming project's `.latexmkrc` handles it:

```perl
$ENV{'TEXMFAUXTREES'} = './cryptocodeh/texmf,';   # trailing comma required
```

**Otherwise** (plain `pdflatex`, TeXShop/TeXworks, an IDE, CI), install the
fonts once into your TeX installation:

```bash
cd cryptocodeh
./install-fonts.sh            # macOS, Linux, WSL, Git Bash/MSYS2/Cygwin
./install-fonts.sh --check    # verify only, change nothing
```

On native Windows PowerShell use `install-fonts.ps1` instead — but note it is
unverified (written without a Windows machine to test on); its header lists the
two-command manual fallback if it misbehaves.

The script detects your OS and whether you run TeX Live/MacTeX or MiKTeX, then
registers the tree (MiKTeX) or copies it into your personal TeX tree (TeX Live,
location supplied by `kpsewhich`, never guessed). It finishes by compiling a
test document, so a clean run means the font genuinely works, not just that
files were copied.

If a build fails with `Metric (TFM) file not found` for
`JetBrainsMono-Regular-tlf-t1`, the search path is unset — that is what the
above fixes. It does not mean the submodule is missing.

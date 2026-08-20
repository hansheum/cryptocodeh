#!/usr/bin/env bash
#
# Install the JetBrains Mono Type1 files that back \monofont into your local
# TeX installation, so pdflatex finds them from any directory.
#
# You probably do NOT need this: if you build with latexmk from the project
# root, the project's .latexmkrc already points kpathsea at cryptocodeh/texmf/
# and everything works with no setup at all. This script is for building with
# plain pdflatex, TeXShop/TeXworks, an IDE, or CI.
#
# Usage:
#   ./install-fonts.sh           install (or re-install), then verify
#   ./install-fonts.sh --check   verify only, change nothing
#   ./install-fonts.sh --help
#
# Works on macOS, Linux, WSL, and Windows under Git Bash / MSYS2 / Cygwin,
# with either TeX Live (incl. MacTeX) or MiKTeX. On native Windows PowerShell,
# run install-fonts.ps1 instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREE="$SCRIPT_DIR/texmf"
PROBE_TFM="JetBrainsMono-Regular-tlf-t1.tfm"

say()  { printf '%s\n' "$*"; }
ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
die()  { printf '\nerror: %s\n' "$*" >&2; exit 1; }

detect_os() {
  case "$(uname -s 2>/dev/null || echo unknown)" in
    Darwin)              echo "macOS" ;;
    Linux)               grep -qi microsoft /proc/version 2>/dev/null \
                           && echo "WSL" || echo "Linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "Windows" ;;
    *)                   echo "unknown" ;;
  esac
}

# TeX Live and MiKTeX both ship kpsewhich but install user files differently.
detect_texdist() {
  command -v kpsewhich >/dev/null 2>&1 || { echo "none"; return; }
  if command -v initexmf >/dev/null 2>&1 \
     || kpsewhich --version 2>/dev/null | grep -qi miktex; then
    echo "miktex"
  else
    echo "texlive"
  fi
}

no_tex_help() {
  local os="$1"
  say "No TeX installation found (kpsewhich is not on your PATH)."
  say ""
  case "$os" in
    macOS)
      say "Install MacTeX:  https://tug.org/mactex/  (or 'brew install --cask mactex')" ;;
    Linux|WSL)
      say "Install TeX Live via your package manager, e.g."
      say "  sudo apt install texlive-full        # Debian/Ubuntu"
      say "  sudo dnf install texlive-scheme-full # Fedora" ;;
    Windows)
      say "Install MiKTeX (https://miktex.org) or TeX Live (https://tug.org/texlive/)." ;;
    *)
      say "Install TeX Live: https://tug.org/texlive/" ;;
  esac
  say ""
  say "If TeX is installed but not on PATH, open a new terminal and retry."
}

# MiKTeX can reference the repo tree in place; nothing gets copied.
install_miktex() {
  say "Registering the font tree with MiKTeX (no files are copied)..."
  initexmf --register-root="$TREE"
  initexmf --update-fndb
  ok "registered $TREE"
}

# TeX Live has no in-place equivalent, so copy into TEXMFHOME. kpsewhich knows
# the right per-OS location (~/Library/texmf, ~/texmf, ...), so we never guess.
install_texlive() {
  local home
  home="$(kpsewhich --var-value=TEXMFHOME)"
  [ -n "$home" ] || die "kpsewhich could not report TEXMFHOME."
  say "Copying the font tree into your personal TeX tree..."
  say "  $home"
  mkdir -p "$home"
  cp -R "$TREE/." "$home/"
  # TEXMFHOME normally has no ls-R cache; refresh only if one exists.
  if [ -e "$home/ls-R" ] && command -v mktexlsr >/dev/null 2>&1; then
    mktexlsr "$home" >/dev/null
    ok "refreshed the filename database"
  fi
  ok "copied 20 files (~700 KB)"
}

verify() {
  local missing=0 f
  say "Verifying that TeX can find the font..."
  for f in "$PROBE_TFM" JetBrainsMono-Regular-tlf-t1.vf \
           JetBrainsMono-Regular.pfb JetBrainsMono.map a_tvwk3a.enc; do
    if kpsewhich "$f" >/dev/null 2>&1; then ok "$f"
    else warn "$f NOT FOUND"; missing=1; fi
  done
  [ "$missing" -eq 0 ] || return 1

  # Finding the files is necessary but not sufficient: compile a real document.
  local tmp; tmp="$(mktemp -d)"
  cat > "$tmp/probe.tex" <<'TEX'
\documentclass{article}
\usepackage[T1,OT1]{fontenc}
\pdfmapfile{+JetBrainsMono.map}
\DeclareFontFamily{T1}{JetBrainsMono}{\hyphenchar\font=-1}
\DeclareFontShape{T1}{JetBrainsMono}{m}{n}{<-> JetBrainsMono-Regular-tlf-t1}{}
\begin{document}
{\fontencoding{T1}\fontfamily{JetBrainsMono}\selectfont 0101}
\end{document}
TEX
  if pdflatex -interaction=batchmode -output-directory="$tmp" \
              "$tmp/probe.tex" >/dev/null 2>&1 && [ -f "$tmp/probe.pdf" ]; then
    ok "test document compiled and embedded the font"
    rm -rf "$tmp"
  else
    warn "test document FAILED to compile"
    grep -m3 -A2 '^!' "$tmp/probe.log" 2>/dev/null || true
    rm -rf "$tmp"
    return 1
  fi
}

main() {
  local mode="install"
  case "${1-}" in
    --check)          mode="check" ;;
    --help|-h)        awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' \
                        "${BASH_SOURCE[0]}"; exit 0 ;;
    "")               ;;
    *)                die "unknown option: $1 (try --help)" ;;
  esac

  local os texdist
  os="$(detect_os)"
  texdist="$(detect_texdist)"
  say "Detected: $os, TeX distribution: $texdist"
  say ""

  [ -f "$TREE/fonts/tfm/lcdftools/JetBrainsMono/$PROBE_TFM" ] \
    || die "$TREE looks incomplete. Run 'git submodule update --init' in the parent project."

  if [ "$texdist" = "none" ]; then no_tex_help "$os"; exit 1; fi

  if [ "$mode" = "install" ]; then
    case "$texdist" in
      miktex)  install_miktex ;;
      texlive) install_texlive ;;
    esac
    say ""
  fi

  if verify; then
    say ""
    say "Done. \\monofont{...} and \\bits{...} will now work from any directory."
  else
    say ""
    if [ "$mode" = "check" ]; then
      say "Not installed yet. Run this script without --check to install."
    else
      say "Installation did not take effect. Please send the output above to Hans."
    fi
    exit 1
  fi
}

main "$@"

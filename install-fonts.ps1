# Install the JetBrains Mono Type1 files that back \monofont into your local
# TeX installation, so pdflatex finds them from any directory.
#
# This is the native-Windows-PowerShell companion to install-fonts.sh.
#
# !! UNVERIFIED: written without access to a Windows machine, so it has never
# !! been run or even parsed by a PowerShell interpreter. install-fonts.sh is
# !! the tested one -- prefer it if you have Git Bash, MSYS2, Cygwin or WSL.
# !! If this script errors out, the whole manual procedure is two commands:
# !!     MiKTeX:   initexmf --register-root=<path-to>\cryptocodeh\texmf
# !!               initexmf --update-fndb
# !!     TeX Live: xcopy /E /I <path-to>\cryptocodeh\texmf %USERPROFILE%\texmf
#
# You probably do NOT need either script: if you build with latexmk from the
# project root, the project's .latexmkrc already points kpathsea at
# cryptocodeh/texmf/ and everything works with no setup at all.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File install-fonts.ps1
#   powershell -ExecutionPolicy Bypass -File install-fonts.ps1 -Check

param([switch]$Check)

$ErrorActionPreference = 'Stop'

$TreeDir  = Join-Path $PSScriptRoot 'texmf'
$ProbeTfm = 'JetBrainsMono-Regular-tlf-t1.tfm'
$Probes   = @($ProbeTfm, 'JetBrainsMono-Regular-tlf-t1.vf',
              'JetBrainsMono-Regular.pfb', 'JetBrainsMono.map', 'a_tvwk3a.enc')

function Write-Ok   ($m) { Write-Host "  ok    $m" }
function Write-Warn ($m) { Write-Host "  warn  $m" }

function Test-Tool ($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Get-TexDistribution {
    if (-not (Test-Tool 'kpsewhich')) { return 'none' }
    if (Test-Tool 'initexmf')        { return 'miktex' }
    return 'texlive'
}

# MiKTeX can reference the repo tree in place; nothing gets copied.
function Install-ForMiktex {
    Write-Host 'Registering the font tree with MiKTeX (no files are copied)...'
    & initexmf "--register-root=$TreeDir"
    & initexmf --update-fndb
    Write-Ok "registered $TreeDir"
}

# TeX Live has no in-place equivalent, so copy into TEXMFHOME. kpsewhich knows
# the right location for this machine, so we never guess.
function Install-ForTexlive {
    $texmfHome = (& kpsewhich --var-value=TEXMFHOME | Select-Object -First 1)
    if (-not $texmfHome) { throw 'kpsewhich could not report TEXMFHOME.' }
    $texmfHome = $texmfHome.Trim().Replace('/', '\')
    Write-Host 'Copying the font tree into your personal TeX tree...'
    Write-Host "  $texmfHome"
    New-Item -ItemType Directory -Force -Path $texmfHome | Out-Null
    Copy-Item -Path (Join-Path $TreeDir '*') -Destination $texmfHome -Recurse -Force
    Write-Ok 'copied 20 files (~700 KB)'
}

function Test-Installation {
    Write-Host 'Verifying that TeX can find the font...'
    $missing = $false
    foreach ($f in $Probes) {
        & kpsewhich $f | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Ok $f }
        else { Write-Warn "$f NOT FOUND"; $missing = $true }
    }
    if ($missing) { return $false }

    # Finding the files is necessary but not sufficient: compile a real document.
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $tex = @'
\documentclass{article}
\usepackage[T1,OT1]{fontenc}
\pdfmapfile{+JetBrainsMono.map}
\DeclareFontFamily{T1}{JetBrainsMono}{\hyphenchar\font=-1}
\DeclareFontShape{T1}{JetBrainsMono}{m}{n}{<-> JetBrainsMono-Regular-tlf-t1}{}
\begin{document}
{\fontencoding{T1}\fontfamily{JetBrainsMono}\selectfont 0101}
\end{document}
'@
    Set-Content -Path (Join-Path $tmp 'probe.tex') -Value $tex -Encoding ASCII
    & pdflatex -interaction=batchmode -output-directory="$tmp" (Join-Path $tmp 'probe.tex') | Out-Null
    $compiled = ($LASTEXITCODE -eq 0)
    if ($compiled) {
        Write-Ok 'test document compiled and embedded the font'
    } else {
        Write-Warn 'test document FAILED to compile'
        $log = Join-Path $tmp 'probe.log'
        if (Test-Path $log) {
            Select-String -Path $log -Pattern '^!' | Select-Object -First 3 | Out-Host
        }
    }
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    return $compiled
}

$dist = Get-TexDistribution
Write-Host "Detected: Windows, TeX distribution: $dist"
Write-Host ''

if (-not (Test-Path (Join-Path $TreeDir "fonts\tfm\lcdftools\JetBrainsMono\$ProbeTfm"))) {
    Write-Host "error: $TreeDir looks incomplete."
    Write-Host "Run 'git submodule update --init' in the parent project."
    exit 1
}

if ($dist -eq 'none') {
    Write-Host 'No TeX installation found (kpsewhich is not on your PATH).'
    Write-Host ''
    Write-Host 'Install MiKTeX (https://miktex.org) or TeX Live (https://tug.org/texlive/).'
    Write-Host 'If TeX is installed but not on PATH, open a new terminal and retry.'
    exit 1
}

if (-not $Check) {
    if ($dist -eq 'miktex') { Install-ForMiktex } else { Install-ForTexlive }
    Write-Host ''
}

if (Test-Installation) {
    Write-Host ''
    Write-Host 'Done. \monofont{...} and \bits{...} will now work from any directory.'
    exit 0
} else {
    Write-Host ''
    if ($Check) { Write-Host 'Not installed yet. Run without -Check to install.' }
    else        { Write-Host 'Installation did not take effect. Please send the output above to Hans.' }
    exit 1
}

# QMCDecoder
## Overview
Decrypt / Decode QQMusic QMC (qmcv2) with tail is "STag" in Julia.

***ONLY SUPPORT QMCv2/rc4/mflac***
## Installation

```julia-repl
(@v1.10) pkg> add https://github.com/xing8star/QMCDecoder.jl
(@v1.10) pkg> add https://github.com/xing8star/SafeThrow.jl
```

## Example
```julia
using QMCDecoder
mflac_file="yourqqmusicfile.mflac0.flac"
ekey="yourkey"
isqmc(mflac_file)
decode(mflac_file,ekey)
```

## Script

Optional in [].

```bash
julia --project=script script/dump.jl "yourmusic.mflac0.flac" "ekey" ["output file name"]
```
"output file name" no need extension suffix.

dump2.jl firstly need to instantiate the 'script' project.
```bash
julia --project=script script/dump2.jl --keep -i "yourmusic.mflac0.flac"/"musics_dir/" [-d "player_process_db"] [-o "output file dir"]
```

Default database is "player_process_db". Please ensure the sqlite is extracted in Android.
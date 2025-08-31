$Base = "https://docs.google.com/spreadsheets/d/e/2PACX-1vSMZUMH-iOTJNbYJE6baVXmEqBr97Ljbp18zpv98CzVKfIOKcvk9leOs8r_F9QFlX4JR-H9P_Ik9uJv/pub?gid="
$OutDir = "config"
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Download($gid, $outName) {
  $u = "$Base$gid&single=true&output=csv"   # < Никакого /export здесь!
  Write-Host "GET $u"
  Invoke-WebRequest -Uri $u -OutFile (Join-Path $OutDir $outName) -ErrorAction Stop
  "Imported $OutDir\$outName"
}

Download 1901154897 "evo.csv"
Download 1487510312 "gen.csv"
Download 1797890220 "init.csv"

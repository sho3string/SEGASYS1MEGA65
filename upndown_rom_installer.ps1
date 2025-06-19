# Up'n Down ROM Builder - PowerShell 5.1+
Clear-Host

$WorkingDirectory = Get-Location
$OutputPath = Join-Path $WorkingDirectory "arcade\upndown"

# XOR Table for encryption
$XORTable = [byte[]](
    0x08,0x88,0x00,0x80,0xa0,0x20,0x80,0x00,0xa8,0xa0,0x28,0x20,0x88,0xa8,0x80,0xa0,
    0x88,0x80,0x08,0x00,0x28,0x08,0xa8,0x88,0x88,0xa8,0x80,0xa0,0x28,0x08,0xa8,0x88,
    0x88,0xa8,0x80,0xa0,0xa0,0x20,0x80,0x00,0xa8,0xa0,0x28,0x20,0xa8,0xa0,0x28,0x20,
    0x88,0x80,0x08,0x00,0x88,0xa8,0x80,0xa0,0x88,0xa8,0x80,0xa0,0x88,0xa8,0x80,0xa0,
    0xa0,0x20,0x80,0x00,0xa0,0x20,0x80,0x00,0x08,0x88,0x00,0x80,0x28,0x08,0xa8,0x88,
    0x88,0xa8,0x80,0xa0,0x88,0x80,0x08,0x00,0x88,0xa8,0x80,0xa0,0x28,0x08,0xa8,0x88,
    0x88,0xa8,0x80,0xa0,0x88,0xa8,0x80,0xa0,0x88,0xa8,0x80,0xa0,0x88,0xa8,0x80,0xa0,
    0x88,0x80,0x08,0x00,0x88,0x80,0x08,0x00,0x08,0x88,0x00,0x80,0x28,0x08,0xa8,0x88
)

	Write-Host "+-----------------------------------+"
	Write-Host "|  Building Up'n Down Arcade ROMs   |"
	Write-Host "+-----------------------------------+"

	# Ensure directories
	New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

	# Build CPU ROM (concatenate files)
	$cpuRomFiles = @("epr5516a.129", "epr5517a.130", "epr-5518.131", "epr-5519.132")
	$cpuBytes = @()
	foreach ($file in $cpuRomFiles) {
		$cpuBytes += [System.IO.File]::ReadAllBytes((Join-Path $WorkingDirectory $file))
	}
	[System.IO.File]::WriteAllBytes((Join-Path $OutputPath "rom1.bin"), $cpuBytes)
	Write-Host "CPU ROM built"

	# Copy non-encrypted data
	$nonEncFiles = @("epr-5520.133", "epr-5521.134")
	$nonEncBytes = @()
	foreach ($file in $nonEncFiles) {
		$nonEncBytes += [System.IO.File]::ReadAllBytes((Join-Path $WorkingDirectory $file))
	}
	[System.IO.File]::WriteAllBytes((Join-Path $OutputPath "rom2.bin"), $nonEncBytes)
	Write-Host "Non-encrypted ROM copied"

	# Copy sound ROM
	$sndRomFiles = @("epr-5535.3","epr-5535.3")
	$sndBytes = @()
	foreach ($file in $sndRomFiles) {
		$sndBytes += [System.IO.File]::ReadAllBytes((Join-Path $WorkingDirectory $file))
	}
	[System.IO.File]::WriteAllBytes((Join-Path $OutputPath "epr-5535.3"), $sndBytes)
	Write-Host "Sound ROM copied"
	

	# Copy tile ROMs
	$tileFiles = @("epr-5527.82", "epr-5526.65", "epr-5525.81", "epr-5524.64", "epr-5523.80", "epr-5522.63")
	foreach ($file in $tileFiles) {
		Copy-Item -Path (Join-Path $WorkingDirectory $file) -Destination $OutputPath
	}
	Write-Host "Tile ROMs copied"

	# Build sprite ROM (concatenate two files twice)
	$spriteFiles = @("epr-5514.86", "epr-5515.93", "epr-5514.86", "epr-5515.93")
	$spriteBytes = @()
	foreach ($file in $spriteFiles) {
		$spriteBytes += [System.IO.File]::ReadAllBytes((Join-Path $WorkingDirectory $file))
	}
	[System.IO.File]::WriteAllBytes((Join-Path $OutputPath "sprites.bin"), $spriteBytes)
	Write-Host "Sprite ROM built"

	# Copy lookup PROM
	Copy-Item -Path (Join-Path $WorkingDirectory "pr-5317.106") -Destination $OutputPath
	Write-Host "Lookup PROM copied"

	# Dump XOR table
	[System.IO.File]::WriteAllBytes((Join-Path $OutputPath "xortable.bin"), $XORTable)
	Write-Host "XOR table dumped"

	# Create empty UDCFG file (filled with 0xFF)
	$length = 74
	$emptyBytes = ,0xFF * $length
	[System.IO.File]::WriteAllBytes((Join-Path $OutputPath "udcfg"), $emptyBytes)
	Write-Host "Blank udcfg created"
	Write-Host "All done!"

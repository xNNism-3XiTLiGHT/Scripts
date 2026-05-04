# USB Drive Speed Test
# Measures sequential write and read speed of a USB drive
# Set Execution policy before:
# "Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"

Clear-Host

Write-Host "USB Drive Speed Test" -ForegroundColor Cyan
Write-Host "===================="
Write-Host ""

#################
# Show all disks and volumes in Windows
# Run PowerShell as Administrator for the best results

Clear-Host

Write-Host "Disk Overview" -ForegroundColor Cyan
Write-Host "============="
Write-Host ""

# Physical disks
Write-Host "Physical Disks:" -ForegroundColor Yellow

Get-Disk | Select-Object `
    Number,
    FriendlyName,
    SerialNumber,
    BusType,
    PartitionStyle,
    OperationalStatus,
    HealthStatus,
    @{Name="Size_GB"; Expression={[math]::Round($_.Size / 1GB, 2)}} |
Format-Table -AutoSize

Write-Host ""
Write-Host "Volumes / Drive Letters:" -ForegroundColor Yellow

# Volumes with drive letters
Get-Volume | Select-Object `
    DriveLetter,
    FileSystemLabel,
    FileSystem,
    DriveType,
    HealthStatus,
    OperationalStatus,
    @{Name="Size_GB"; Expression={[math]::Round($_.Size / 1GB, 2)}},
    @{Name="Free_GB"; Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}} |
Sort-Object DriveLetter |
Format-Table -AutoSize

Write-Host ""
Write-Host "Partitions:" -ForegroundColor Yellow
#################

# Ask for drive letter
$DriveLetter = Read-Host "Enter the USB drive letter, e.g. E"

# Remove colon if the user entered it
$DriveLetter = $DriveLetter.Trim().TrimEnd(":")

# Build drive path
$Drive = "$DriveLetter`:"

# Check if drive exists
if (-not (Test-Path $Drive)) {
    Write-Host "Error: Drive $Drive does not exist." -ForegroundColor Red
    exit
}

# Ask for test file size
$SizeInput = Read-Host "Enter the test file size in MB, e.g. 1024"

# Validate test file size
$ParsedSize = 0
if (-not [int]::TryParse($SizeInput, [ref]$ParsedSize)) {
    Write-Host "Error: The size must be a whole number in MB." -ForegroundColor Red
    exit
}

$SizeMB = $ParsedSize

if ($SizeMB -le 0) {
    Write-Host "Error: The size must be greater than 0 MB." -ForegroundColor Red
    exit
}

# Check available free space
try {
    $DriveInfo = Get-PSDrive -Name $DriveLetter
    $FreeSpaceMB = [math]::Round($DriveInfo.Free / 1MB, 2)

    if ($FreeSpaceMB -lt $SizeMB) {
        Write-Host "Error: Not enough free space on drive $Drive." -ForegroundColor Red
        Write-Host "Available: $FreeSpaceMB MB"
        Write-Host "Required:  $SizeMB MB"
        exit
    }
}
catch {
    Write-Host "Warning: Could not check free space." -ForegroundColor Yellow
}

# Create unique test file path
$File = Join-Path $Drive ("speedtest_{0}.tmp" -f ([guid]::NewGuid().ToString()))

# General settings
$BufferSize = 1MB
$Data = New-Object byte[] $BufferSize
$Buffer = New-Object byte[] $BufferSize

Write-Host ""
Write-Host "Drive:      $Drive"
Write-Host "Test file:  $File"
Write-Host "Test size:  $SizeMB MB"
Write-Host ""
Write-Host "Starting write test..."

# -------------------------
# Write test
# -------------------------

$fs = $null
$sw = [System.Diagnostics.Stopwatch]::StartNew()

try {
    $fs = [System.IO.File]::Open(
        $File,
        [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )

    for ($i = 0; $i -lt $SizeMB; $i++) {
        $fs.Write($Data, 0, $Data.Length)
    }

    $fs.Flush()
}
catch {
    Write-Host "Error during write test:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}
finally {
    if ($null -ne $fs) {
        $fs.Close()
        $fs.Dispose()
    }

    $sw.Stop()
}

$WriteSpeed = $SizeMB / $sw.Elapsed.TotalSeconds

Write-Host ("Write speed: {0:N2} MB/s" -f $WriteSpeed)
Write-Host ""
Write-Host "Starting read test..."

# -------------------------
# Read test
# -------------------------

$fs = $null
$sw = [System.Diagnostics.Stopwatch]::StartNew()

try {
    $fs = [System.IO.File]::Open(
        $File,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read
    )

    while ($fs.Read($Buffer, 0, $Buffer.Length) -gt 0) {
        # Read file into buffer
    }
}
catch {
    Write-Host "Error during read test:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}
finally {
    if ($null -ne $fs) {
        $fs.Close()
        $fs.Dispose()
    }

    $sw.Stop()
}

$ReadSpeed = $SizeMB / $sw.Elapsed.TotalSeconds

Write-Host ("Read speed:  {0:N2} MB/s" -f $ReadSpeed)

# -------------------------
# Cleanup
# -------------------------

Write-Host ""
Write-Host "Cleaning up test file..."

try {
    Remove-Item $File -Force
    Write-Host "Test file deleted successfully."
}
catch {
    Write-Host "Warning: Could not delete test file:" -ForegroundColor Yellow
    Write-Host $File -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

# -------------------------
# Simple evaluation
# -------------------------

Write-Host ""
Write-Host "Result summary"
Write-Host "=============="
Write-Host ("Write speed: {0:N2} MB/s" -f $WriteSpeed)
Write-Host ("Read speed:  {0:N2} MB/s" -f $ReadSpeed)

Write-Host ""

if ($WriteSpeed -lt 10) {
    Write-Host "Write performance: Very slow" -ForegroundColor Red
}
elseif ($WriteSpeed -lt 30) {
    Write-Host "Write performance: Basic USB drive" -ForegroundColor Yellow
}
elseif ($WriteSpeed -lt 100) {
    Write-Host "Write performance: Usable USB 3.x drive" -ForegroundColor Green
}
elseif ($WriteSpeed -lt 300) {
    Write-Host "Write performance: Fast USB drive" -ForegroundColor Green
}
else {
    Write-Host "Write performance: Very fast USB drive / external SSD class" -ForegroundColor Cyan
}

if ($ReadSpeed -lt 30) {
    Write-Host "Read performance: Slow" -ForegroundColor Red
}
elseif ($ReadSpeed -lt 100) {
    Write-Host "Read performance: Basic USB drive" -ForegroundColor Yellow
}
elseif ($ReadSpeed -lt 300) {
    Write-Host "Read performance: Good USB 3.x drive" -ForegroundColor Green
}
else {
    Write-Host "Read performance: Very fast USB drive / external SSD class" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Test completed."

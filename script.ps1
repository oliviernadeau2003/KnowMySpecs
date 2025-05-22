# -----------------------------------------
#   Author : Olivier Nadeau
#   Date   : 23/02/2024
# -----------------------------------------

$ArrComputers = "."

# Define hashtable to translate raw values to friendly text for CPU architecture
$ArchitectureMap = @{
    0 = 'x86'
    1 = 'MIPS'
    2 = 'Alpha'
    3 = 'PowerPC'
    6 = 'ia64'
    9 = 'x64'
}

# Define hashtable to translate raw values to friendly text for network adapter type
$AdapterTypeID_map = @{
    0  = 'Ethernet 802.3'
    1  = 'Token Ring 802.5'
    2  = 'Fiber Distributed Data Interface (FDDI)'
    3  = 'Wide Area Network (WAN)'
    4  = 'LocalTalk'
    5  = 'Ethernet using DIX header format'
    6  = 'ARCNET'
    7  = 'ARCNET (878.2)'
    8  = 'ATM'
    9  = 'Wireless'
    10 = 'Infrared Wireless'
    11 = 'Bpc'
    12 = 'CoWan'
    13 = '1394'
}

# Define calculated property for CPU architecture
$CPUArchitecture = @{
    Name       = 'Architecture'
    Expression = {
        $ArchitectureMap[[int]$_.Architecture]
    }
}

Clear-Host
Write-Host "Loading ..."
foreach ($Computer in $ArrComputers) {
    $computerCPU = Get-CimInstance -ClassName Win32_Processor
    $computerGPU = Get-CimInstance -ClassName Win32_VideoController
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $computerMemory = Get-CimInstance -ClassName Win32_PhysicalMemory
    $computerDisk = Get-CimInstance -ClassName Win32_LogicalDisk
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
    $networkAdapters = Get-NetAdapter
    $bios = Get-CimInstance -ClassName Win32_BIOS

    Clear-Host


    Write-Host "System Information for: $($computerSystem.Name)" -BackgroundColor DarkCyan
    "-------------------------------------------------------"
    Write-Host "Operating System Information:" -BackgroundColor Magenta
    $uptime = (Get-Date) - $operatingSystem.LastBootUpTime
    "   Name: $($operatingSystem.Caption)"
    "   Version: $($operatingSystem.Version)"
    "   Architecture: $($operatingSystem.OSArchitecture)"
    "   System Uptime: $($uptime.Days) Days, $($uptime.Hours) Hours, $($uptime.Minutes) Minutes"
    "-------------------------------------------------------"    
    Write-Host "CPU Information:" -BackgroundColor Magenta
    "   Name: $($computerCPU.Name)"
    "   Manufacturer: $($computerCPU.Manufacturer)"
    "   Number of Cores: $($computerCPU.NumberOfCores)"
    "   Number of Logical Processors: $($computerCPU.NumberOfLogicalProcessors)"
    "   Max Clock Speed: $($computerCPU.MaxClockSpeed) GHz"
    "   Architecture: $($computerCPU | Select-Object -Property $CPUArchitecture | Select-Object -ExpandProperty Architecture)"
    "-------------------------------------------------------"

    Write-Host "GPU Information:" -BackgroundColor Magenta
    foreach ($gpu in $computerGPU) {
        $qwMemorySize = (Get-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0*" -Name HardwareInformation.qwMemorySize -ErrorAction SilentlyContinue)."HardwareInformation.qwMemorySize"
        "   Device Name: $($gpu.Description)"
        "   Adapter Compatibility: $($gpu.AdapterCompatibility)"
        "   VRAM: $([math]::round($qwMemorySize / 1GB)) GB"
        "   Driver Version: $($gpu.DriverVersion)"
        "-------------------------------------------------------"
    }

    Write-Host "Memory Information:" -BackgroundColor Magenta
    $totalRAM = ($computerMemory | Measure-Object -Property Capacity -Sum).Sum
    # "   Total Physical Memory:"
    "   Total RAM: $([math]::Round($totalRAM / 1GB, 2)) GB"
    "   Memory Slots:"
    "   ----------------------------------------------------"
    foreach ($memory in $computerMemory) {
        $memoryCapacityGB = [math]::Round($memory.Capacity / 1GB, 2)
        "   RAM Module Manufacturer: $($memory.Manufacturer)"
        "   Model: $($memory.PartNumber)"
        "   Capacity: $($memoryCapacityGB) GB"
        "   Speed: $($memory.Speed) MHz"
        "   ----------------------------------------------------"
    }
    ""
    "-------------------------------------------------------"

    Write-Host "Disk Information:" -BackgroundColor Magenta
    "   ----------------------------------------------------"
    foreach ($disk in $computerDisk) {
        "   Drive: $($disk.DeviceID)"
        "   Volume Name: $($disk.VolumeName)"
        "   File System: $($disk.FileSystem)"
        "   Total Size: $([math]::Round($disk.Size / 1GB, 2)) GB"
        "   Free Space: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB"
        "   ----------------------------------------------------"
    }
    "-------------------------------------------------------"

    Write-Host "Network Information:" -BackgroundColor Magenta
    "   ----------------------------------------------------"
    foreach ($adapter in $networkAdapters) {
        $ipAddresses = (Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex).IPAddress
        "   Adapter Name: $($adapter.Name)"
        "   Adapter Type: $($AdapterTypeID_map[[int]$adapter.AdapterTypeID])"
        "   MAC Address: $($adapter.MacAddress)"
        "   IP Address (Local): $($ipAddresses[$($ipAddresses.Lenght) -1])"
        "   IP Address (External) : $((Invoke-WebRequest ifconfig.me/ip).content)"
        "   Status: $($adapter.Status)"        
        "   ----------------------------------------------------"
    }
    "-------------------------------------------------------"

    Write-Host "BIOS Information:" -BackgroundColor Magenta
    "   Manufacturer: $($bios.Manufacturer)"
    "   Version: $($bios.SMBIOSBIOSVersion)"
    "   Release Date: $($bios.ReleaseDate)"
    "----------------------------------------------------"
}
Pause

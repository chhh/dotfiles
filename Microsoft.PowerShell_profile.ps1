# Set tab completion to work like in Bash (complete up to longest common sequence)
Set-PSReadlineKeyHandler -Key Tab -Function Complete


# Autocompletion for git
# Requires: PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
Import-Module posh-git


# Ssh key automatic loading
# Requires: PowerShellGet\Install-Module posh-sshell -Scope CurrentUser -Force
# Starting module SshAgent requires that 'ssh-agent' service is 'Enabled'
# From an elevated prompt: Get-Service ssh-agent | Set-Service -StartupType Manual
Import-Module posh-sshell
Start-SshAgent


Set-PSReadlineOption -BellStyle None

# Starship (alternative to Oh my posh)
#Invoke-Expression (&starship init powershell)


# Oh my posh
# oh-my-posh init pwsh | Invoke-Expression
# Set the theme for oh-my-posh
# Requires: Install-Module oh-my-posh -Scope AllUsers
#Import-Module oh-my-posh
#Set-PoshPrompt -Theme ~\dotfiles\theme-ohmy-powershell.json


# msconvert
function Convert-ToMzml
{
    param(
        # [Parameter(Mandatory=$true)][string]$RawGlob,
        [string]$RawGlob,
        [string]$OutDir,
        [switch]$NoCentroid,
        [switch]$Mz64,
        [switch]$Dryrun
    )
    if ($RawGlob -eq '') { $RawGlob = '*.raw' }
    if ($OutDir -eq '') { $OutDir = '.' }
    $filter = " --filter `"peakPicking vendor`""
    $mzBits = '--mz32'
    if ($Mz64) { $mzBits = '--mz64' }
    if ($NoCentroid) {
        $filter = ''
	$ext = '.as-is.mzML'
    } else {
        $ext = '.centroid.mzML'
    }
    $cmd = "msconvert --ext $ext --outdir `"$OutDir`" --mzML --simAsSpectra $mzBits --inten32 -z$filter $RawGlob"
    Write-Output $cmd 
    if ($Dryrun) { return }

    else { Invoke-Expression $cmd }
}

function Run-Diann-Multi
{
    param(
        [Parameter(Mandatory=$true)][string]$Lib,
        [Parameter(Mandatory=$false)][string]$OutDir,
        [Parameter(Mandatory=$false, HelpMessage="E.g. C:\Data\Dmitry\230223\*.raw")][string]$RawGlob = "*.raw",
        [Parameter(Mandatory=$false, HelpMessage="E.g. *blank*")][string]$ExcludeGlob = "*blank*",
        [switch]$NoRecurse,
        [switch]$Dryrun
    )
    if ($OutDir -eq '') { $OutDir = "." }

    Write-Output "Lib:         [$Lib]"
    Write-Output "OutDir:      [$OutDir]"
    Write-Output "RawGlob:     [$RawGlob]"
    Write-Output "ExcludeGlob: [$ExcludeGlob]"
    Write-Output "NoRecurse:   [$NoRecurse]"
    Write-Output "Dryrun:      [$Dryrun]"


    $cmdRecurse = '-Recurse'
    if ($NoRecurse) { $cmdRecurse='' }

    $cmd = "Get-ChildItem $cmdRecurse -Exclude `"$ExcludeGlob`" -Path `"$RawGlob`""
    Write-Output $cmd
    Invoke-Expression $cmd
    
    if ($Dryrun) { 
        return 
    } else {
        $YesNo = Read-Host "Run DIA-NN for these files? (y/n)"
        if ("y" -ne $YesNo) { 
            Write-Output "Not running DIA-NN"
            return
        }
    }
    Write-Output "Running DIA-NN"

    $files = Invoke-Expression $cmd
    foreach ($file in $files) {
        Write-Host "Processing: $file"
        Run-Diann -Lib $Lib -OutDir $OutDir -Raw $file
    }

    Write-Output "Run-Diann-Multi finished"
}

function Run-Diann
{
    param(
        [Parameter(Mandatory=$true)][string]$Raw,
        [Parameter(Mandatory=$true)][string]$Lib,
        [Parameter(Mandatory=$false)][string]$OutDir,
        # [Parameter(Mandatory=$false)][string]$Exe = 'DiaNN.exe',
        [Parameter(Mandatory=$false)][string]$Exe = 'diann',
        [Parameter(Mandatory=$false)][int]$Threads = 16,
        [Parameter(Mandatory=$false)][int]$Verbosity = 2,
        [switch]$Dryrun
    )
    
    if (!(Test-Path $Raw)) {
        Write-Warning "Raw file not exists: [$Raw]"
        return
    }
    if (!(Test-Path $Lib)) {
        Write-Warning "Lib file not exists: [$Lib]"
        return
    }

    $rawFnLessExt = [System.IO.Path]::GetFileNameWithoutExtension($Raw)
    $rawDir = [System.IO.Path]::GetDirectoryName($Raw)
    if ($OutDir -eq '') {
        $dirForReports = [System.IO.Path]::Combine($rawDir, $rawFnLessExt)
    } else {
        $dirForReports = [System.IO.Path]::Combine($OutDir, $rawFnLessExt)
    }
    $diannReportTsv = [System.IO.Path]::Combine($dirForReports, "${rawFnLessExt}.diann-report.tsv")

    $varOpts = @(
        $Exe,
        "--f", "`"$Raw`"",
        "--out", "`"$diannReportTsv`"",
        "--lib", "`"$Lib`""
        "--threads", $Threads, 
        "--verbose", $Verbosity
    )

    $fixedOpts = @(
        "--report-lib-info"
        "--qvalue", "0.01",
        "--matrices", 
        "--met-excision",
        "--cut", "K*,R*",
        "--var-mods", "2"
        "--var-mod", "UniMod:35,15.994915,M"
        "--var-mod", "UniMod:1,42.010565,*n"
        "--monitor-mod", "UniMod:1"
        "--relaxed-prot-inf",
        "--smart-profiling",
        "--peak-center"
    )

    $opts = $varOpts + $fixedOpts

    $cmd = $opts -join ' '
    Write-Output $cmd

    if (!$Dryrun) {
        New-Item -Force -Path $dirForReports -ItemType "directory"
        Write-Warning $cmd
        Invoke-Expression $cmd
    }
}

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
    if ($NoCentroid) { $filter = '' }
    $cmd = "msconvert --outdir `"$OutDir`" --mzML --simAsSpectra $mzBits --inten32 -z$filter $RawGlob"
    if ($Dryrun) { Write-Output $cmd }
    else { Invoke-Expression $cmd }
}


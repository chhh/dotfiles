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
oh-my-posh init pwsh | Invoke-Expression
# Set the theme for oh-my-posh
# Requires: Install-Module oh-my-posh -Scope AllUsers
#Import-Module oh-my-posh
#Set-PoshPrompt -Theme ~\dotfiles\theme-ohmy-powershell.json


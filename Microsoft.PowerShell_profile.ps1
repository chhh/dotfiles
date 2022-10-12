# Set tab completion to work like in Bash (complete up to longest common sequence)
Set-PSReadlineKeyHandler -Key Tab -Function Complete

# Autocompletion for git
# Requires: PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
Import-Module posh-git

Set-PSReadlineOption -BellStyle None

# Starship (alternative to Oh my posh)
Invoke-Expression (&starship init powershell)


# Oh my posh
#oh-my-posh init pwsh | Invoke-Expression
# Set the theme for oh-my-posh
# Requires: Install-Module oh-my-posh -Scope AllUsers
#Import-Module oh-my-posh
#Set-PoshPrompt -Theme ~\dotfiles\theme-ohmy-powershell.json


# DomainJoin

<#
.SYNOPSIS
    Interactive script to rename a computer and join it to the domain in the correct OU based on its name, without multiple reboots or pre-staging in AD.
.DESCRIPTION
    Get current hostname and prompt for a new name, then determine which OU to join based on the new name. The Add-Computer cmdlet will prompt for credentials
    then join the computer to the domain in the OU we determined, rename it, then prompt to reboot.
.NOTES
    v4.2.2
#>

# Elevate to Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

function Join-Domain
{
    Clear-Host

    $OldName = hostname
    $NewName = Read-Host -Prompt "Enter new name"

    if ($NewName -like "*02*") {$OU = "OU=02,OU=xxx,DC=xxx"}
    elseif ($NewName -like "*03-?1*") {$OU = "OU=03-1,OU=xxx,DC=xxx"}
    elseif ($NewName -like "*03-?3*") {$OU = "OU=03-3,OU=xxx,DC=xxx"}
    elseif ($NewName -like "*04*") {$OU = "OU=04,OU=xxx,DC=xxx"}
    elseif ($NewName -like "*05*") {$OU = "OU=05,OU=xxx,DC=xxx"}
    elseif ($NewName -like "*08*") {$OU = "OU=08,OU=xxx,DC=xxx"}
    elseif ($NewName -like "*40*") {$OU = "OU=40,OU=xxx,DC=xxx"}

    # If we can't find the correct OU, just drop it into the root and move it manually later
    else {$OU = "OU=xxx,DC=xxx"}

    # Prompt to confirm and display the OU so we're sure it's correct
    Write-Host ""
    $Confirm = Read-Host -Prompt "Join $NewName to $OU ? (Y/N)"
    switch ($Confirm)
    {
        Y {
            Add-Computer -ComputerName $OldName -DomainName domain -NewName $NewName -OUPath $OU -PassThru -Verbose
            if ($? -eq $true) {
                Write-Host ""
                Write-Warning "The computer $OldName will be renamed $NewName after you restart."
                Write-Host ""
                $Reboot = Read-Host -Prompt "Would you like to restart now? (Y/N)"
                switch ($Reboot)
                {
                    Y {Restart-Computer}
                    N {Exit}
                }
            } else {
                Write-Host ""
                Read-Host -Prompt "Press Enter to go back and try again"
                Join-Domain
            }
        }
        N {
            Write-Host ""
            Write-Host "Operation cancelled. Going back..."
            Start-Sleep -Seconds 3
            Join-Domain
        } 
    }
}

Join-Domain

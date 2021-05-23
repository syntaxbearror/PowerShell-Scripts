# -----------------------------------------------------------------
# Check for Existent Key for Microsoft Windows Meltdown / Spectre Mitigation
# Created by: Christopher Clai (syntaxbearror.io)
# -----------------------------------------------------------------
# Version 1.0 (February 25, 2018)
# -----------------------------------------------------------------
#
# Example of running the script:
# .\specmelt_compkeycheck.ps1 -mode [local|remote] (Choose what method to run the script, local mode or remote)
# .\specmelt_compkeycheck.ps1 -mode remote -target SYSTEM (Specify a single remote system to run on. If none entered, it looks for systems.txt) 
#
#
# ##### CHANGELOG ########
# Version 1.0
# - It is born!
#
#
# Important Links
# Guidance Regarding Reg Keys
# https://support.microsoft.com/en-us/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution
#
#


# Retrieve parameters if run on a single use.

    param (
	    [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,HelpMessage='Local or Remote Mode')]
	    $mode,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,HelpMessage='Target System')]
	    $target
    )

    
# -----
# DO NOT EDIT ANYTHING BELOW THIS LINE. It has a high likelihood it will affect script functionality.
# -----


# Begin Transcript

    Start-Transcript -Path "check_spectre.txt" -Append



# Begin to process

    if ($mode -eq "local") {

        # Let's transcribe our actions
        write-host "Running in local mode..."

        $servers = "localhost"

    } 
    elseif ($mode -eq "remote") {

        write-host "Running in remote mode..."

        if ($target) {
    
            # We have a single target defined.
            $servers = $target

        } else {
    
            # We have no target defined. Pull from servers.txt
            $path = "systems.txt"
            if(![System.IO.File]::Exists($path)){
              Write-Host "Systems.TXT file not found in script directory. This is necessary if no target defined. Exiting."
              Return
            }
            else
            {
                #Pull the list
                $servers = Get-content systems.txt
            }
    
        }
    }




           # Set taction to zero
           $taction = 0


ForEach ($server in $servers) {

    Write-Host "Checking $server"

    
    If(Test-Connection -BufferSize 32 -Count 1 -ComputerName $server -Quiet) {
    
        Write-Host "System is Online. Checking registry..."

        $ScriptBlock = {

                            If ((Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\QualityCompat -Name 'cadca5fe-87d3-4b96-b7fb-a231484277cc' -EA 0).'cadca5fe-87d3-4b96-b7fb-a231484277cc' -eq '0') { 
 
                                # The key is present on this system.
                                Write-Host "Key is Present."

                            } Else { 

                                # The key is absent on this system. :(
                                Write-Host "Key is Absent. Check AV Compatability before application!" 

                            }

                        }

        Invoke-Command -ComputerName $server -ScriptBlock $ScriptBlock -ArgumentList ($server)
        $taction++

    } Else {

        #System is offline
        Write-Host "System is Offline. Skipping..."
    
    }


}

# Write the result
Write-Host $taction "Systems Checked out of "$servers.count "Systems."

# Complete the Transcript
Stop-Transcript
#
#Start-DataCollectorSet.ps1
#
function Start-DataCollectorSet 
{
<#
.SYNOPSIS
   The function is starting a Data Collector Set (DCS) in local or remote computer
.DESCRIPTION
   PowerShell version 4 or higher
   The function is starting a DCS in local or remote computer. If DCS is already working it will be restarted.
   The function supports parallel(group servers) and consistent execution.
.PARAMETER Computer
   Local or remote computer name. Use FQDN, NET-BIOS name or "localhost" for local computer, array is possible
   For example, @("Server1", "Server2", "Server3", "Server4")
.PARAMETER DCSName
   Data Collector Set name
.PARAMETER ComputersCountPerBatch
   This parameter enable parallel processing and run script for servers batch. Range for batch 4...32.
.EXAMPLE
   $Servers = Get-Content -Path \\server\share\serverlist.txt
   Start-DataCollectorSet -ComputerName $Servers -DCSName Proccessor_Time -ComputersCountPerBatch 6
.EXAMPLE
   $Servers = "srv1", "srv2", "srv3", "srv4"
   Start-DataCollectorSet -CN $servers -DCSName Disk_Time
.EXAMPLE
   Start-DCS server-test2 Memory
   Short variant using the function (only for PowerShell version 5 and later)
#>
	[CmdletBinding ()]
	[Alias("Start-DCS")]
	Param (
	[PARAMETER (Mandatory=$true, ValueFromPipeline=$true, Position=0)][Alias("CN")][string[]]$ComputerName,
	[PARAMETER (Mandatory=$true, Position=1)][string]$DCSName,
	[PARAMETER (Mandatory=$false, Position=2)][Alias("Batch")][ValidateRange(4,32)][byte]$ComputersCountPerBatch
	)
	Process 
	{
		If ($ComputersCountPerBatch) 
		{
			Write-Host "Script will be executed by parallel processes"
			$i = 0
			$j = $ComputersCountPerBatch - 1
			$BatchStep = 1
			While ($i -lt $ComputerName.Count) 
			{
				$ComputerBatch = $ComputerName[$i..$j]
				Invoke-Command -ComputerName $ComputerBatch -ScriptBlock `
				{
					Param ($DCSName)
					$Computer = $env:COMPUTERNAME
					$PerfMonDataCollectorSet = New-Object -ComObject Pla.DataCollectorSet
					$PerfMonDataCollectorSet.Query($DCSName, $null)
					If ($? -eq $true) 
					{
						If ($PerfMonDataCollectorSet.Status -eq "1") 
						{
							$PerfMonDataCollectorSet.Stop($false)
							While ($PerfMonDataCollectorSet.Status -eq "1") 
							{
								Start-Sleep -Milliseconds 500
							}
							$PerfMonDataCollectorSet.Start($false)
							While ($PerfMonDataCollectorSet.Status -eq "0") 
							{
								Start-Sleep -Milliseconds 500
							}
							Write-Host "Data Collector Set `"$DCSName`" has been started on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
						}
						Else 
						{
							$PerfMonDataCollectorSet.Start($false)
							While ($PerfMonDataCollectorSet.Status -eq "0") 
							{
								Start-Sleep -Milliseconds 500
							}
							Write-Host "Data Collector Set `"$DCSName`" has been started on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
						}
					}
					Else 
					{
						$PerfMonDataCollectorSet.Query("System\System Diagnostics", $null)
						If ($? -eq $true) 
						{
							Write-Host "Warning! Connection to PerfMon System is established, but Data Collector Set `"$DCSName`" is NOT found on computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
						}
						Else 
						{
							Write-Host "Error! Connection to PerfMon System is NOT established on computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
						}
					}
				} -ArgumentList $DCSName
				$BatchStep++
				$i = $j + 1
				$j += $ComputersCountPerBatch
			}
		}
		Else 
		{
			Write-Host "Script will be executed by consistent processes"
			foreach ($Computer in $ComputerName) 
			{
				Invoke-Command -ComputerName $Computer -ScriptBlock `
				{
					Param ($DCSName, $Computer)
					$PerfMonDataCollectorSet = New-Object -ComObject Pla.DataCollectorSet
					$PerfMonDataCollectorSet.Query($DCSName, $null)
					If ($? -eq $true) 
					{
						If ($PerfMonDataCollectorSet.Status -eq "1") 
						{
							$PerfMonDataCollectorSet.Stop($false)
							While ($PerfMonDataCollectorSet.Status -eq "1") 
							{
								Start-Sleep -Milliseconds 500
							}
							$PerfMonDataCollectorSet.Start($false)
							While ($PerfMonDataCollectorSet.Status -eq "0") 
							{
								Start-Sleep -Milliseconds 500
							}
							Write-Host "Data Collector Set `"$DCSName`" has been started on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
						}
						Else 
						{
							$PerfMonDataCollectorSet.Start($false)
							While ($PerfMonDataCollectorSet.Status -eq "0") 
							{
								Start-Sleep -Milliseconds 500
							}
							Write-Host "Data Collector Set `"$DCSName`" has been started on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
						}
					}
					Else 
					{
						$PerfMonDataCollectorSet.Query("System\System Diagnostics", $null)
						If ($? -eq $true) 
						{
							Write-Host "Warning! Connection to PerfMon System is established, but Data Collector Set `"$DCSName`" is NOT found on computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
						}
						Else 
						{
							Write-Host "Error! Connection to PerfMon System is NOT established on computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
						}
					}
				} -ArgumentList $DCSName, $Computer
			}
		}
	}
}
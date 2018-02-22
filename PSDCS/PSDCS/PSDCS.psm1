#
#PSDCS.psm1
#
<#
Windows PowerShell Performance Monitor Data Collection Set (PSDCS) Module
This module PSDCS contains a set of wrapper scripts that enable a user to start, stop, add and remove Data Collector Set in Performance Monitor
Cmdlets from this module can parallel processing up to 32 computers per batch by using Invoke-Command.
The module PSDCS contains function Write-Log. You can use it for writing log to file.
#>
#
#FUNCTIONS
#
#Add-DataCollectorSet.ps1
#
function Add-DataCollectorSet 
{
<#
.SYNOPSIS
   The function is adding a Data Collector Set (DCS) in local or remote computer
.DESCRIPTION
   PowerShell version 4 or higher
   The function is adding a DCS in local or remote computer. If the DCS is already present, it will be stopped, removed and added again, when -Force flag is present.
   The function supports parallel(group servers) and consistent execution.
.PARAMETER ComputerName
   Local or remote computer name. Use FQDN, NET-BIOS name or "localhost" for local computer, array is possible
   For example, @("Server1", "Server2", "Server3", "Server4")
.PARAMETER DCSName
   Data Collector Set name
.PARAMETER ComputersCountPerBatch
   This parameter enable parallel processing and run script for servers batch. Range for batch 4...32.
.PARAMETER DCSXMLTemplate
   Path to XML-template
.EXAMPLE
   $Servers = Get-Content -Path \\server\share\serverlist.txt
   Add-DataCollectorSet -ComputerName $Servers -DCSName Proccessor_Time -ComputersCountPerBatch 8 -DCSXMLTemplate "C:\DCS_templates\test.xml" -Force
   #Regular using the function
.EXAMPLE
   $Servers = "srv1", "srv2", "srv3", "srv4"
   Add-DataCollectorSet -ComputerName $Servers -DCSName Memory -DCSXMLTemplate "C:\DCS_templates\Memory.xml"
   #Adding DCS to servers consistently
.EXAMPLE
   Add-DataCollectorSet -ComputerName @("srv1", "srv2", "srv3", "srv4") -DCSName Memory -DCSXMLTemplate "C:\DCS_templates\Memory.xml"
   #Adding DCS to servers consistently, same variant
.EXAMPLE
   Add-DataCollectorSet -CN server-test1 -DCSName Disk_Time -XML "C:\DCS_templates\test.xml"
.EXAMPLE
   Add-DCS server-test2 Memory 8 "C:\test.xml"
   #Short variant using the function (only for PowerShell version 5 and later)
#>
	[CmdletBinding ()]
	[Alias("Add-DCS")]
	Param (
	[PARAMETER (Mandatory=$true, ValueFromPipeline=$true, Position=0)][Alias("CN")][string[]]$ComputerName,
	[PARAMETER (Mandatory=$true, Position=1)][string]$DCSName,
	[PARAMETER (Mandatory=$false, Position=2)][Alias("Batch")][ValidateRange(4,32)][byte]$ComputersCountPerBatch,
	[PARAMETER (Mandatory=$true, Position=3)][string][Alias("XML")][IO.FileInfo]$DCSXMLTemplate,
	[PARAMETER (Mandatory=$false)][switch]$Force
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
					Param ($DCSName, $Force)
					$Computer = $env:COMPUTERNAME
					$PerfMonDataCollectorSet = New-Object -ComObject Pla.DataCollectorSet
					$PerfMonDataCollectorSet.Query($DCSName, $null)
					If ($? -eq $true) 
					{
						If ($Force) 
						{
							If ($PerfMonDataCollectorSet.Status -eq "1") 
							{
								$PerfMonDataCollectorSet.Stop($false)
								While ($PerfMonDataCollectorSet.Status -eq "1") 
								{
									Start-Sleep -Milliseconds 500
								}
								$PerfMonDataCollectorSet.Delete()
								If ($? -eq $true)
								{
									$PerfMonDataCollectorSet.SetXml($XMLData)
									If ($? -eq $true) 
									{
										$null = $PerfMonDataCollectorSet.Commit("$DCSName", $null, 0x0003)
										If ($? -eq $true)
										{
											Write-Host "Data Collector Set `"$DCSName`" has been added to computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
										}
										Else 
										{
											Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
										}
									}
									Else 
									{
										Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not add XML-data to COM-object!" -ForegroundColor Red -BackgroundColor DarkBlue
									}
								}
								Else 
								{
									Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not delete old DCS!" -ForegroundColor Red -BackgroundColor DarkBlue
								}
							}
							Else 
							{
								$PerfMonDataCollectorSet.Delete()
								If ($? -eq $true)
								{
									$PerfMonDataCollectorSet.SetXml($XMLData)
									If ($? -eq $true) 
									{
										$null = $PerfMonDataCollectorSet.Commit("$DCSName", $null, 0x0003)
										If ($? -eq $true)
										{
											Write-Host "Data Collector Set `"$DCSName`" has been added to computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
										}
										Else 
										{
											Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
										}
									}
									Else 
									{
										Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not add XML-data to COM-object!" -ForegroundColor Red -BackgroundColor DarkBlue
									}
								}
								Else 
								{
									Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not delete old DCS!" -ForegroundColor Red -BackgroundColor DarkBlue
								}
							}
						}
						Else 
						{
							Write-Host "Data Collector Set `"$DCSName`" is already present on computer `"$Computer`". Use -Force flag for rewriting Data Collector Set `"$DCSName`"." -ForegroundColor Yellow -BackgroundColor DarkBlue
						}
					}
					Else 
					{
						$PerfMonDataCollectorSet.Query("System\System Diagnostics", $null)
						If ($? -eq $true) 
						{
							$PerfMonDataCollectorSet.SetXml($XMLData)
							If ($? -eq $true) 
							{
								$null = $PerfMonDataCollectorSet.Commit("$DCSName", $null, 0x0003)
								If ($? -eq $true)
								{
									Write-Host "Data Collector Set `"$DCSName`" has been added on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
								}
								Else 
								{
									Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added! " -ForegroundColor Red -BackgroundColor DarkBlue
								}
							}
							Else 
							{
								Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not add XML-data to COM-object!" -ForegroundColor Red -BackgroundColor DarkBlue
							}
						}
						Else 
						{
							Write-Host "Error! Connection to PerfMon System is NOT established on computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
						}
					}
				} -ArgumentList $DCSName, $Force
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
					Param ($DCSName, $Force)
					$Computer = $env:COMPUTERNAME
					$PerfMonDataCollectorSet = New-Object -ComObject Pla.DataCollectorSet
					$PerfMonDataCollectorSet.Query($DCSName, $null)
					If ($? -eq $true) 
					{
						If ($Force) 
						{
							If ($PerfMonDataCollectorSet.Status -eq "1") 
							{
								$PerfMonDataCollectorSet.Stop($false)
								While ($PerfMonDataCollectorSet.Status -eq "1") 
								{
									Start-Sleep -Milliseconds 500
								}
								$PerfMonDataCollectorSet.Delete()
								If ($? -eq $true)
								{
									$PerfMonDataCollectorSet.SetXml($XMLData)
									If ($? -eq $true) 
									{
										$null = $PerfMonDataCollectorSet.Commit("$DCSName", $null, 0x0003)
										If ($? -eq $true)
										{
											Write-Host "Data Collector Set `"$DCSName`" has been added to computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
										}
										Else 
										{
											Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
										}
									}
									Else 
									{
										Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not add XML-data to COM-object!" -ForegroundColor Red -BackgroundColor DarkBlue
									}
								}
								Else 
								{
									Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not delete old DCS!" -ForegroundColor Red -BackgroundColor DarkBlue
								}
							}
							Else 
							{
								$PerfMonDataCollectorSet.Delete()
								If ($? -eq $true)
								{
									$PerfMonDataCollectorSet.SetXml($XMLData)
									If ($? -eq $true) 
									{
										$null = $PerfMonDataCollectorSet.Commit("$DCSName", $null, 0x0003)
										If ($? -eq $true)
										{
											Write-Host "Data Collector Set `"$DCSName`" has been added to computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
										}
										Else 
										{
											Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
										}
									}
									Else 
									{
										Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not add XML-data to COM-object!" -ForegroundColor Red -BackgroundColor DarkBlue
									}
								}
								Else 
								{
									Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not delete old DCS!" -ForegroundColor Red -BackgroundColor DarkBlue
								}
							}
						}
						Else 
						{
							Write-Host "Data Collector Set `"$DCSName`" is already present on computer `"$Computer`". Use -Force flag for rewriting Data Collector Set `"$DCSName`"." -ForegroundColor Yellow -BackgroundColor DarkBlue
						}
					}
					Else 
					{
						$PerfMonDataCollectorSet.Query("System\System Diagnostics", $null)
						If ($? -eq $true) 
						{
							$PerfMonDataCollectorSet.SetXml($XMLData)
							If ($? -eq $true) 
							{
								$null = $PerfMonDataCollectorSet.Commit("$DCSName", $null, 0x0003)
								If ($? -eq $true)
								{
									Write-Host "Data Collector Set `"$DCSName`" has been added on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
								}
								Else 
								{
									Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added! " -ForegroundColor Red -BackgroundColor DarkBlue
								}
							}
							Else 
							{
								Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not add XML-data to COM-object!" -ForegroundColor Red -BackgroundColor DarkBlue
							}
						}
						Else 
						{
							Write-Host "Error! Connection to PerfMon System is NOT established on computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
						}
					}
				} -ArgumentList $DCSName, $Force
			}
		}
	}
}
#
#Remove-DataCollectorSet.ps1
#
function Remove-DataCollectorSet 
{
<#
.SYNOPSIS
   The function is removing a Data Collector Set (DCS) in local or remote computer
.DESCRIPTION
   PowerShell version 4 or higher
   The function is removing a DCS in local or remote computer. If the DCS is already present, it will be stopped, removed and added again, when -Force flag is present.
   The function supports parallel(group servers) and consistent execution.
.PARAMETER ComputerName
   Local or remote computer name. Use FQDN, NET-BIOS name or "localhost" for local computer, array is possible
   For example, @("Server1", "Server2", "Server3", "Server4")
.PARAMETER DCSName
   Data Collector Set name
.PARAMETER ComputersCountPerBatch
   This parameter enable parallel processing and run script for servers batch. Range for batch 4...32.
.EXAMPLE
   $Servers = Get-Content -Path \\server\share\serverlist.txt
   Remove-DataCollectorSet -ComputerName $Servers -DCSName Proccessor_Time -ComputersCountPerBatch 8
   #Regular using the function
.EXAMPLE
   $Servers = "srv1", "srv2", "srv3", "srv4"
   Remove-DataCollectorSet -ComputerName $Servers -DCSName Memory
   #Removing DCS from servers consistently
.EXAMPLE
   Add-DataCollectorSet -ComputerName @("srv1", "srv2", "srv3", "srv4") -DCSName Memory -DCSXMLTemplate "C:\DCS_templates\Memory.xml"
   #Removing DCS from servers consistently, same variant
.EXAMPLE
   Remove-DataCollectorSet -CN server-test1 -DCSName Disk_Time
.EXAMPLE
   Remove-DCS server-test2 Memory 8
   #Short variant using the function (only for PowerShell version 5 and later)
#>
	[CmdletBinding ()]
	[Alias("Remove-DCS")]
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
								Start-Sleep -Milliseconds 100
							}
							$PerfMonDataCollectorSet.Delete()
							If ($? -eq $true)
							{
								Write-Host "Data Collector Set `"$DCSName`" has been removed on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
							}
							Else 
							{
								Write-Host "Error! Can NOT remove Data Collector Set `"$DCSName`" from computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
							}
						}
						Else 
						{
							$PerfMonDataCollectorSet.Delete()
							If ($? -eq $true)
							{
								Write-Host "Data Collector Set `"$DCSName`" has been removed on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
							}
							Else 
							{
								Write-Host "Error! Can NOT remove Data Collector Set `"$DCSName`" from computer `"$Computer`"!" -ForegroundColor Red -BackgroundColor DarkBlue
							}
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
				} -ArgumentList $DCSName, $Force
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
					Param ($DCSName, $Force)
					$Computer = $env:COMPUTERNAME
					$PerfMonDataCollectorSet = New-Object -ComObject Pla.DataCollectorSet
					$PerfMonDataCollectorSet.Query($DCSName, $null)
					If ($? -eq $true) 
					{
						If ($Force) 
						{
							If ($PerfMonDataCollectorSet.Status -eq "1") 
							{
								$PerfMonDataCollectorSet.Stop($false)
								While ($PerfMonDataCollectorSet.Status -eq "1") 
								{
									Start-Sleep -Milliseconds 100
								}
								$PerfMonDataCollectorSet.Delete()
								If ($? -eq $true)
								{
									Write-Host "Data Collector Set `"$DCSName`" has been removed on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
								}
								Else 
								{
									Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not delete old DCS!" -ForegroundColor Red -BackgroundColor DarkBlue
								}
							}
							Else 
							{
								$PerfMonDataCollectorSet.Delete()
								If ($? -eq $true)
								{
									Write-Host "Data Collector Set `"$DCSName`" has been removed on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
								}
								Else 
								{
									Write-Host "Error! Data Collector Set `"$DCSName`" has NOT been added to computer `"$Computer`"! Can not delete old DCS!" -ForegroundColor Red -BackgroundColor DarkBlue
								}
							}
						}
						Else 
						{
							Write-Host "Data Collector Set `"$DCSName`" is already present on computer `"$Computer`". Use -Force flag for rewriting Data Collector Set `"$DCSName`"." -ForegroundColor Yellow -BackgroundColor DarkBlue
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
				} -ArgumentList $DCSName, $Force
			}
		}
	}
}
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
#
#Stop-DataCollectorSet.ps1
#
function Stop-DataCollectorSet 
{
<#
.SYNOPSIS
   The function is stopping a Data Collector Set (DCS) in local or remote computer
.DESCRIPTION
   PowerShell version 4 or higher
   The function is stopping a DCS in local or remote computer.
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
   Stop-DataCollectorSet -ComputerName $Servers -DCSName Proccessor_Time -ComputersCountPerBatch 6
.EXAMPLE
   $Servers = "srv1", "srv2", "srv3", "srv4"
   Stop-DataCollectorSet -CN $servers -DCSName Disk_Time
.EXAMPLE
   Stop-DCS server-test2 Memory
   Short variant using the function (only for PowerShell version 5 and later)
#>
	[CmdletBinding ()]
	[Alias("Stop-DCS")]
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
							Write-Host "Data Collector Set `"$DCSName`" has been stopped on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
						}
						Else 
						{
							Write-Host "Data Collector Set `"$DCSName`" is NOT working now on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
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
							Write-Host "Data Collector Set `"$DCSName`" has been stopped on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
						}
						Else 
						{
							Write-Host "Data Collector Set `"$DCSName`" is NOT working now on computer `"$Computer`"." -ForegroundColor Green -BackgroundColor DarkBlue
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
#
#Write-Log.ps1
#
function Write-Log 
{
<#
.SYNOPSIS
   The function writing messages to file.
.DESCRIPTION
   PowerShell version 4 or higher
   This function writes messages to log file with severity level.
   Alias for this function "wl"
.PARAMETER Message
   A message to log-file
.PARAMETER Path
   Log-file path
.PARAMETER Level
   Severity level ("Success", "Information", "Warning", "Error")
.EXAMPLE
   Write-Log -Message "This message will be written to $Path with date-time before text with severity level $Level" -Level "Error" -Path "C:\test.log"
   Full using
.EXAMPLE
   Write-Log "Test message will be written to $Path with severity Error" Error
   Using without naming parameters with severity level Error
.EXAMPLE
   wl "Test message"
   Short variant using the function (only for PowerShell version 5 and later)
#>
	[CmdletBinding ()]
	[Alias("wl")]
	Param (
	[PARAMETER(Mandatory=$true, Position=0, ValueFromPipeline=$true)][ValidateNotNullOrEmpty()]$Message,
	[PARAMETER(Mandatory=$false,Position=1)][ValidateSet("Success", "Information", "Warning", "Error")][String]$Level="Information",
	[PARAMETER(Mandatory=$false)][IO.FileInfo]$Path
	)
	Process 
	{
		If (!$Path) 
		{
			$Date = Get-Date -UFormat %Y.%m.%d
			$Path = "$env:TEMP\Write-Log_Function_$Date.log"
		}
		$DateWrite = Get-Date -Format FileDateTime
		$Line = "{0} ***{1}*** {2}" -f $DateWrite, $Level.ToUpper(), $Message
		Add-Content -Path $Path -Value $Line
	}
}
#
Export-ModuleMember -Function "Start-DataCollectorSet", "Stop-DataCollectorSet", "Add-DataCollectorSet", "Remove-DataCollectorSet", "Write-Log" -Alias "Start-DCS", "Stop-DCS", "Add-DCS", "Remove-DCS", "wl"
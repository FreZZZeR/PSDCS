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
		$XMLData = Get-Content -Path $DCSXMLTemplate
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
					Param ($DCSName, $XMLData, $Force)
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
				} -ArgumentList $DCSName, $XMLData, $Force
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
					Param ($DCSName, $XMLData, $Force)
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
				} -ArgumentList $DCSName, $XMLData, $Force
			}
		}
	}
}
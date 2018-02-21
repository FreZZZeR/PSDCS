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
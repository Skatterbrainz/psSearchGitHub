function Search-GitHubRepository {
	<#
	.SYNOPSIS
		Search GitHub repositories for a specific string.
	
	.DESCRIPTION
		Search GitHub repositories for a specific string using the GitHub CLI.
	
	.PARAMETER SearchValue
		The string to search for in the repositories.
	
	.PARAMETER Owner
		The owner of the repositories to search. If not provided, searches all accessible repositories.

	.PARAMETER Summary
		If specified, returns a summary of repositories containing matches instead of detailed match information.
	
	.EXAMPLE
		Search-GitHubRepository -SearchValue "PowerShell" -Owner "skatterbrainz"
		Searches the repositories owned by "skatterbrainz" for the string "PowerShell".
	
	.EXAMPLE
		Search-GitHubRepository -SearchValue "PowerShell" -Summary
		Searches all accessible repositories for the string "PowerShell" and returns a summary of repositories containing matches.
	
	.NOTES
		Requires GitHub CLI (gh) to be installed and authenticated.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)][string]$SearchValue,
		[parameter(Mandatory = $false)][string]$Owner,
		[parameter(Mandatory = $false)][switch]$Summary
	)
	try {
		if ([string]::IsNullOrEmpty($SearchValue)) {
			throw "No SearchValue was provided"
		}
		if ($IsLinux -or $IsMacOS) {
			$cmd = "gh"
		} else {
			$cmd = "gh.exe"
		}
		if (-not (Get-Command $cmd)) {
			throw "Install GitHub CLI first."
		}
		$arglist = "search code `"$SearchValue`""
		if (![string]::IsNullOrEmpty($Owner)) {
			$arglist += " --owner=$Owner"
		}
		$arglist += " --json repository,path,url,textMatches"

		# Build arguments array for direct execution
		$ghArgs = @('search', 'code', $SearchValue)
		if (![string]::IsNullOrEmpty($Owner)) {
			$ghArgs += "--owner=$Owner"
		}
		$ghArgs += @('--json', 'repository,path,url,textMatches')

		Write-Verbose "Command: $cmd $($arglist -join ' ')"
		$textmatches = & $cmd $ghArgs | ConvertFrom-Json
		Write-Host "$($textmatches.count) matches found" -ForegroundColor Cyan
		if ($Summary.IsPresent) {
			$textmatches | Select-Object -Property @{l = 'Repository'; e = { $_.repository.nameWithOwner } } |
				Select-Object -Property Repository | Sort-Object -Unique -Property Repository
		} else {
			$textmatches |
				Select-Object -Property path,url,@{l = 'Repository'; e = { $_.repository.nameWithOwner } },
					@{l = 'Text'; e = { $_.textMatches.fragment } } |
				Sort-Object -Property Repository
		}
	} catch {
		[pscustomobject]@{
			Status   = "Error"
			Message  = $_.Exception.Message
			Trace    = $_.Exception.ScriptStackTrace
			Category = $_.Exception.CategoryInfo.Activity
		}
	}
}

function Search-GitHubGist {
	<#
	.SYNOPSIS
		Search GitHub gists for a specific string.
	
	.DESCRIPTION
		Search GitHub gists for a specific string using the GitHub CLI.
	
	.PARAMETER SearchValue
		The string to search for in the gists.
	
	.PARAMETER IncludeContent
		If specified, includes the matching content in the results.

	.PARAMETER Limit
		The maximum number of gists to search. Default is 100.

	.EXAMPLE
		Search-GitHubGist -SearchValue "PowerShell" -IncludeContent -Limit 50
		Searches the gists for the string "PowerShell", includes matching content, and limits the search to 50 gists.

	.EXAMPLE
		Search-GitHubGist -SearchValue "PowerShell"
		Searches the gists for the string "PowerShell" without including matching content and uses the default limit of 100 gists.
	
	.NOTES
		Requires GitHub CLI (gh) to be installed and authenticated.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$true)][string]$SearchValue,
		[parameter(Mandatory=$false)][switch]$IncludeContent,
		[parameter(Mandatory=$false)][int]$Limit = 100
	)
	try {
		if ([string]::IsNullOrEmpty($SearchValue)) {
			throw "No SearchValue was provided"
		}
		if ($IsLinux -or $IsMacOS) {
			$cmd = "gh"
		} else {
			$cmd = "gh.exe"
		}
		if (-not (Get-Command $cmd)) {
			throw "Install GitHub CLI first."
		}
		$ghArgs = @('gist', 'list', '--filter', $SearchValue, '--include-content', '--limit', $Limit)
		$gists = & $cmd @ghArgs
		<#
		Filter results to map lines to properties as follows:

		b5db0c256f73f300eaea8c50d7973f9d boxstarter_sample2.txt
			BoxStarter Examples
				Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | iex

		No spaces at the beginning of the line = id and filename
		4 spaces at the beginning of the line = description
		8 spaces at the beginning of the line = matching content
		#>
		$results = @()
		for ($i = 0; $i -lt $gists.Count; $i++) {
			$line = $gists[$i]
			if (![string]::IsNullOrEmpty($line)) {
				if (-not $line.StartsWith(" ")) {
					# Line with no leading spaces = id and filename
					$gistId      = $line.Substring(0, 32)
					$filename    = $line.Substring(33)
					$description = ""
					$content     = ""

					# Check next lines for description (4 spaces) and content (8 spaces)
					if ($i + 1 -lt $gists.Count -and $gists[$i + 1].StartsWith("    ") -and -not $gists[$i + 1].StartsWith("        ")) {
						$description = $gists[$i + 1].Trim()
						if ($i + 2 -lt $gists.Count -and $gists[$i + 2].StartsWith("        ")) {
							$content = $gists[$i + 2].Trim()
						}
					}

					$results += [pscustomobject]@{
						id          = $gistId
						filename    = $filename
						gistname    = $description
						content     = $content
					}
				}
			}
		}

		$results | foreach-object {
			$gistId   = $_.id
			$filename = $_.filename
			Write-Verbose "gist id: $gistId - filename: $filename"
			$gistContent = gh gist view $gistId --raw
			if ($IncludeContent.IsPresent) {
				Write-Verbose "Including content in results"
				$gistContent | select-string -Pattern $SearchValue -List |
					select-object -Property @{l='gistId';e={$gistId}}, @{l='filename';e={$filename}}, @{l='line';e={$_.LineNumber}}, @{l='match';e={$_.Line}}
			} else {
				$gistContent | select-string -Pattern $SearchValue -List |
					select-object -Property @{l='gistId';e={$gistId}}, @{l='filename';e={$filename}}, @{l='line';e={$_.LineNumber}}
			}
		}
	} catch {
		[pscustomobject]@{
			Status   = "Error"
			Message  = $_.Exception.Message
			Trace    = $_.Exception.StackTrace
			Category = $_.Exception.CategoryInfo.Activity
		}
	}
}
function Search-GitHub {
	<#
	.SYNOPSIS
	Search GitHub repositories or gists for a specified value.

	.DESCRIPTION
	This function uses the GitHub CLI to search either GitHub repositories or gists for a specified
	value. It can include content in the search results and limit the number of results returned.

	.PARAMETER Target
	Specifies whether to search 'Gist' or 'Repo'.
	Valid values are 'Gist' and 'Repo'.

	.PARAMETER SearchValue
	The value to search for in the specified target.

	.PARAMETER Owner
	(Optional) The owner of the repositories to search (only applicable when searching repositories).

	.PARAMETER IncludeContent
	Switch to include content in the search results (only applicable when searching gists).

	.PARAMETER Limit
	The maximum number of results to return (default is 100).

	.EXAMPLE
	Search-GitHub -Target Gist -SearchValue "Invoke-WebRequest" -IncludeContent -Limit 50
	Searches gists for the value "Invoke-WebRequest", includes content in the results, and limits the results to 50.

	.EXAMPLE
	Search-GitHub -Target Repo -SearchValue "PowerShell"
	Searches repositories for the value "PowerShell".

	.EXAMPLE
	Search-GitHub -Target Repo -SearchValue "psGitHubSearch" -Owner "skatterbrainz" -IncludeContent
	Searches repositories owned by "skatterbrainz" for the value "psGitHubSearch" and includes content in the results.

	.NOTES
	Requires GitHub CLI to be installed and authenticated.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)][string][ValidateSet('Gist', 'Repo')]$Target,
		[parameter(Mandatory = $true)][string]$SearchValue,
		[parameter(Mandatory = $false)][string]$Owner,
		[parameter(Mandatory = $false)][switch]$IncludeContent,
		[parameter(Mandatory = $false)][int]$Limit = 100
	)

	try {
		if ([string]::IsNullOrEmpty($SearchValue)) {
			throw "No SearchValue was provided"
		}
		if (-not (Get-Command "gh")) {
			throw "Install GitHub CLI first."
		}
		if ($IsLinux) {
			$cmd = "gh"
		} else {
			$cmd = "gh.exe"
		}

		if ($Target -eq 'Gist') {
			$ghArgs = @('gist', 'list', '--filter', $SearchValue, '--include-content', '--limit', $Limit)
			$gists = & $cmd @ghArgs
			<#
			Filter results to map lines to gh output properties as follows:

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
						$gistId = $line.Substring(0, 32)
						$filename = $line.Substring(33)
						$description = ""
						$content = ""

						# Check next lines for description (4 spaces) and content (8 spaces)
						if ($i + 1 -lt $gists.Count -and $gists[$i + 1].StartsWith("    ") -and -not $gists[$i + 1].StartsWith("        ")) {
							$description = $gists[$i + 1].Trim()
							if ($i + 2 -lt $gists.Count -and $gists[$i + 2].StartsWith("        ")) {
								$content = $gists[$i + 2].Trim()
							}
						}

						$results += [pscustomobject]@{
							id       = $gistId
							filename = $filename
							gistname = $description
							content  = $content
						}
					}
				}
			} # end for

			$results | ForEach-Object {
				$gistId = $_.id
				$filename = $_.filename
				Write-Verbose "gist id: $gistId - filename: $filename"
				$gistContent = gh gist view $gistId --raw
				if ($IncludeContent.IsPresent) {
					Write-Verbose "Including content in results"
					$gistContent | Select-String -Pattern $SearchValue -List |
						Select-Object -Property @{l = 'gistId'; e = { $gistId } }, @{l = 'filename'; e = { $filename } }, @{l = 'line'; e = { $_.LineNumber } }, @{l = 'match'; e = { $_.Line } }
				} else {
					$gistContent | Select-String -Pattern $SearchValue -List |
						Select-Object -Property @{l = 'gistId'; e = { $gistId } }, @{l = 'filename'; e = { $filename } }, @{l = 'line'; e = { $_.LineNumber } }
				}
			} # end foreach
		} else {
			$ghArgs = @('search', 'code', $SearchValue)
			if (![string]::IsNullOrEmpty($Owner)) {
				$ghArgs += "--owner=$Owner"
			}
			$ghArgs += @('--json', 'repository,path,url,textMatches')

			Write-Verbose "Command: $cmd $($arglist -join ' ')"
			$textmatches = & $cmd $ghArgs | ConvertFrom-Json
			Write-Host "$($textmatches.count) matches found" -ForegroundColor Cyan
			if (-not $IncludeContent.IsPresent) {
				$textmatches | Select-Object -Property @{l = 'Repository'; e = { $_.repository.nameWithOwner } } |
					Select-Object -Property Repository | Sort-Object -Unique -Property Repository
			} else {
				$textmatches |
					Select-Object -Property path, url, @{l = 'Repository'; e = { $_.repository.nameWithOwner } },
					@{l = 'Text'; e = { $_.textMatches.fragment } } |
						Sort-Object -Property Repository
			}
		} # end else
	} catch {
		[pscustomobject]@{
			Status   = "Error"
			Message  = $_.Exception.Message
			Trace    = $_.Exception.StackTrace
			Category = $_.Exception.CategoryInfo.Activity
		}
	}
}
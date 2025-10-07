function GetGitHubRelease {
    # DO NOT USE `[CmdletBinding()]` or [Parameter()]
    # We splat the parameters from Install-GitHubRelease and we need to ignore the extras
    param(
        [string]$Org,

        [string]$Repo,

        [string]$Tag = 'latest'
    )
    Write-Debug "Org: $Org, Repo: $Repo, Tag: $Tag"

    # Handle the Org parameter being a org/repo/version or the full URL to a project or release
    if ($Org -match "github.com") {
        Write-Debug "Org is a github.com url: $Org"
        if ($Org -match "releases/tag/.*") {
            $Org, $Repo, $Tag = $Org.split("/").where({ "github.com" -eq $_ }, "SkipUntil")[1, 2, -1]
            if ($PSBoundParameters.ContainsKey('Repo')) {
                Write-Warning "Repo is ignored when passing a full URL to a release/tag"
            }
            if ($PSBoundParameters.ContainsKey('Tag')) {
                Write-Warning "Tag is ignored when passing a full URL to a release/tag"
            }
        } else {
            if ($PSBoundParameters.ContainsKey('Repo')) {
                Write-Warning "Repo is ignored when passing a project URL"
                if (!$PSBoundParameters.ContainsKey('Tag')) {
                    Write-Debug "   and repo specified without Tag: $Repo"
                    $Tag = $Repo
                }
            }
            $Org, $Repo = $Org.Split('/').where({ "github.com" -eq $_ }, "SkipUntil")[1, 2]
        }
    } elseif ($Org -match "/") {
        Write-Debug "Org is a / separated string: $Org"
        if ($PSBoundParameters.ContainsKey('Repo')) {
            Write-Warning "Repo is ignored when passing a / separated string for Org"
            if (!$PSBoundParameters.ContainsKey('Tag')) {
                Write-Debug "   and repo specified without Tag: $Repo"
                $Tag = $Repo
            }
        }
        $Org, $Repo, $Version = $Org.Split('/')
        if ($Version -and -not $PSBoundParameters.ContainsKey('Repo') -and -not $PSBoundParameters.ContainsKey('Tag')) {
            $Tag = @($Version)[0]
        }
    }

    Write-Verbose "Checking GitHub $Org/$Repo for '$Tag'"

    $headers = @{
        Accept     = 'application/vnd.github.v3+json'
    }
    if( $env:GITHUB_TOKEN ) {
        $headers.Authorization = "bearer $($Env:GITHUB_TOKEN)"
    }

    $Result = if ($Tag -eq 'latest') {
        Invoke-RestMethod "https://api.github.com/repos/$Org/$Repo/releases/$Tag" -Headers $headers -Verbose:$false
    } else {
        Invoke-RestMethod "https://api.github.com/repos/$Org/$Repo/releases/tags/$Tag" -Headers $headers -Verbose:$false
    }

    Write-Verbose "found release $($Result.tag_name) for $Org/$Repo"
    $result | Add-Member -NotePropertyMembers @{
        Org  = $Org
        Repo = $Repo
    } -PassThru
}

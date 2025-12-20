# FromGitHub

A cross-platform PowerShell module to install single-file executable tools directly from GitHub releases.

## Key features

- Find the latest release or a specified tagged release
- Detect the local Operating System and architecture, and download the appropriate asset
- Verify download checksums if available
- Automatically rename or decompress the downloaded files
- Ensure the tool is on your PATH (works cross-platform by adding to /usr/bin or Local AppData/Programs/Tools)

If any of the automatic detection fails, [file an issue](https://github.com/Jaykul/FromGitHub/issues), but there is manual control for overriding the OS, Architecture, install path (BinDir), and the name of the executable file to copy.

## Latest Features

Now handles removing the version from the file names, e.g. in GitTower's git-flow assets, the files are named like `git-flow-v1.0.0-windows-amd64.exe`, but we need the executable to just be `git-flow.exe`

## Examples

You can install by providing the owner and repository name as separate parameters, the full URL to the repository, or even the release page for a specific version, etc.

Install `Flux` from the FluxCD/Flux2 project:

```powershell
Install-FromGitHub FluxCD Flux2
```

Install `chezmoi` from the twpayne/chezmoi project:

```powershell
Install-FromGitHub twpayne/chezmoi
```

Install `earthly` from the earthly/earthly project:

```powershell
Install-FromGitHub https://github.com/earthly/earthly
```

Install a specific version of `fzf` from the junegunn/fzf repository:

```powershell
Install-FromGitHub junegunn fzf 0.66.1

```

Install the latest `rg` from the BurntSushi/ripgrep repository

```powershell
Install-FromGitHub BurntSushi ripgrep
```

Install `opentofu` from the https://github.com/opentofu/opentofu repository

```powershell
Install-FromGitHub https://github.com/opentofu/opentofu
```

Install `yq` version v4.50.1 from the mikefarah/yq's release page URL:

```powershell
Install-FromGitHub https://github.com/mikefarah/yq/releases/tag/v4.50.1
```

Install `bat` and `fd` from sharkdp's projects:

```powershell
Install-FromGitHub sharkdp bat
Install-FromGitHub sharkdp fd
```

Install `git-flow` from the GitTower/git-flow-next project:

```powershell
Install-FromGitHub GitTower/git-flow-next
```

## Things this does not do yet

- Support linux packages on release pages (deb, rpm, apk, etc)
- Support better archive formats (7z, etc)

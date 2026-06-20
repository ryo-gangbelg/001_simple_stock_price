# dev.ps1 - Dev workflow automation
# Usage:
#   .\dev.ps1 start <branch-name>   Create and switch to feature/<branch-name>
#   .\dev.ps1 save  [message]        git add + commit
#   .\dev.ps1 pr    [message]        git add + commit + push + create PR

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "save", "pr")]
    [string]$Command,

    [Parameter(Position=1)]
    [string]$Arg
)

function Show-Usage {
    Write-Host "Usage:"
    Write-Host "  .\dev.ps1 start <branch-name>   Create feature/<branch-name>"
    Write-Host "  .\dev.ps1 save  [message]        git add + commit"
    Write-Host "  .\dev.ps1 pr    [message]        git add + commit + push + PR"
}

function Get-CurrentBranch {
    return (git rev-parse --abbrev-ref HEAD).Trim()
}

function Invoke-Gh {
    $gh = if (Get-Command gh -ErrorAction SilentlyContinue) { "gh" } else { "C:\Program Files\GitHub CLI\gh.exe" }
    & $gh @args
}

switch ($Command) {

    "start" {
        if (-not $Arg) {
            Write-Host "Error: specify a branch name. e.g. .\dev.ps1 start my-feature" -ForegroundColor Red
            exit 1
        }
        $branch = "feature/$Arg"
        git checkout -b $branch
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Write-Host "Created branch '$branch'" -ForegroundColor Green
    }

    "save" {
        $branch = Get-CurrentBranch
        if ($branch -eq "main") {
            Write-Host "Error: cannot commit directly to main. Run .\dev.ps1 start <name> first." -ForegroundColor Red
            exit 1
        }
        $message = if ($Arg) { $Arg } else { "wip: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
        git add -A
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        git commit -m $message
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Write-Host "Committed: '$message'" -ForegroundColor Green
    }

    "pr" {
        $branch = Get-CurrentBranch
        if ($branch -eq "main") {
            Write-Host "Error: cannot create PR from main. Run .\dev.ps1 start <name> first." -ForegroundColor Red
            exit 1
        }
        $message = if ($Arg) { $Arg } else { "feat: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }

        git add -A
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        $status = git status --porcelain
        if ($status) {
            git commit -m $message
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        } else {
            Write-Host "Nothing to commit. Creating PR from existing commits." -ForegroundColor Yellow
        }

        git push -u origin $branch
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        Invoke-Gh pr create --base main --head $branch --title $message --body "## Changes`n`n- $message`n`n---`nGenerated with dev.ps1"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        Write-Host "PR created!" -ForegroundColor Green
    }

    default {
        Show-Usage
    }
}

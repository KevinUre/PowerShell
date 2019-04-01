Set-PSReadlineOption -BellStyle None

function Is-Git-Repo($target) {
    Push-Location $target
    $output=$false
    $gitout = git status *>&1
    if ($gitout -match '^fatal: Not a git repository ' ) {
        $output = $false
    } else {
        $output = $true
    }
    Pop-Location
    return $output
}

function Find-Git-Root($target) {
    foreach ($child in Get-ChildItem $target -Directory -Hidden)
    {
        if ($child -match '.git')
        {
            return $target
        }
    }
    Find-Git-Root (Get-Item $target).Parent.FullName
}

function Get-Location-Depth-String {
    $pathList = Get-Location -Stack
    if ($pathList.Count -eq 0) {
        return "" }
    else {
        $topPath = $pathList.Peek()
        $fork = Is-Git-Repo $topPath
        if($fork) {
            $gitRoot = Find-Git-Root (Resolve-Path $topPath)
            $projectName = Split-Path $gitRoot -Leaf
            $output = [Regex]::Match($topPath, "$($projectName).*?$").value
            return "[$output]"
        } else { 
            $output = $topPath -replace '(?<=\\)(.).*?(?=\\)','$1'
            return "[$output]"
        }
    }
}

function shouldDropDown {
    if(Is-Git-Repo .) {return $true}
    elseif((Get-Location -Stack).Count -ne 0) {return $true}
    else {return $false}
}

$GitPromptSettings.DefaultPromptPath = ""

function prompt {
    $prompt = Write-Prompt "$(Get-Location-Depth-String)" -ForegroundColor DarkGray
    $parentPath = Split-Path $((Get-Location).Path) -Parent
    $prompt += Write-Prompt "$($parentPath)" -ForegroundColor White
    if( ($parentPath.Length -gt 0)`
     -And ($parentPath.Substring($parentPath.Length-1) -ne "\"))
    {
        $prompt += Write-Prompt "\" -ForegroundColor White
    }
    $prompt += Write-Prompt "$(Split-Path $((Get-Location).Path) -Leaf)" -ForegroundColor Yellow
    $prompt += & $GitPromptScriptBlock
    $prompt += Write-Prompt "$(if(shouldDropDown) {""`n""} else {})" -ForegroundColor White
    if ($prompt) {$prompt} else {" "}
}

Set-ALias cd+ Push-Location
Set-Alias cd- Pop-Location
function cd= {
    $loc = Get-Location
    while ((Get-Location -Stack).Count -gt 0) {
        Pop-Location }
    Set-Location $loc
}

function cd> {
    if((Get-Location -Stack).Count -eq 0)
    {
        return
    }
    $stackList = New-Object -TypeName System.Collections.Generic.List[string]
    $stack = (Get-Location -Stack).ToArray()
    $stackList.Add((Get-Location).ToString())
    for($i = $stack.Count-1; $i -gt 0; $i--)
    {
        $stackList.Add($stack[$i].ToString())
    }
    Pop-Location
    $endLocation = Get-Location
    cd=
    foreach($dir in $stackList)
    {
        Set-Location $dir
        Push-Location
    }
    Set-Location $endLocation
}

function cd... { for($i = 1; $i -le 02; $i++) { Set-Location .. } }
function cd.... { for($i = 1; $i -le 03; $i++) { Set-Location .. } }
function cd..... { for($i = 1; $i -le 04; $i++) { Set-Location .. } }
function cd...... { for($i = 1; $i -le 05; $i++) { Set-Location .. } }
function cd....... { for($i = 1; $i -le 06; $i++) { Set-Location .. } }
function cd........ { for($i = 1; $i -le 07; $i++) { Set-Location .. } }
function cd......... { for($i = 1; $i -le 08; $i++) { Set-Location .. } }

function cdd ($target) {
    Set-Location $target
    Get-ChildItem
}

Set-Alias which Get-Command

function Nuke($target) {
    $trueTarget = $target #helps with .. and other path slang
    if( $target -eq ".") {
        $trueTarget = Convert-Path .
        Set-Location ..
    }
    Remove-Item $trueTarget -Force -Recurse
}

function Get-Type {
    param(
    [Parameter(Mandatory, ValueFromPipeline)] [object] $object,
    [alias("d")] [Switch] $detailed
    )
    $type = $object.GetType()
    if($detailed) {
        Write-Output $type }
    else {
        Write-Output $type.Name }
}

Set-Alias gt Get-Type

<#
.SYNOPSIS
Function to find contents of files in a directory*
.DESCRIPTION
Recursively* searches current or given directory for any file whose contents match a given regular expression regardless of file extension and returns the line the match was found on as well as the relative path to the file and the line number

*Skips any folder named node_modules by default
.OUTPUTS
The formatted results (i.e. path:line   text)
.PARAMETER pattern
The regular expression to search for. String delimiters seem optional
.PARAMETER rootPath
The top level directory you want to search in
.PARAMETER includeNodeModules
includes the node_module folder name in the search
.PARAMETER includeLineText
includes the text of the line in the file that triggered the match
.PARAMETER includedFiles
expression for including only certain files. supports windows * wildcards, spaces, and multiple patterns can be given seperated by |. use ' marks to insure proper parameterization. explicit use of wildcards on start and end required for partial match support. not intended for use with actual regex input, see: -includedFilesRegex
.PARAMETER excludedFiles
expression for excluding certain files. supports windows * wildcards, spaces, and multiple patterns can be given seperated by |. use ' marks to insure proper parameterization. explicit use of wildcards on start and end required for partial match support. not intended for use with actual regex input, see: -excludedFilesRegex
.PARAMETER excludedDirectories
expression for excluding certain directories. supports windows * wildcards, spaces, and multiple patterns can be given seperated by |. use ' marks to insure proper parameterization. explicit use of wildcards on start and end required for partial match support. not intended for use with actual regex input, see: -excludedDirectoriesRegex . node_modules is excluded by default: see -includeNodeModules
.PARAMETER flat
disables recursive directory searching behavior
.PARAMETER includedFilesRegex
regular expression for including only certain files. multiple patterns can be given seperated by |. use ' marks to insure proper parameterization. can be used along-side of -includedFiles
.PARAMETER excludedFilesRegex
regular expression for excludig certain files. multiple patterns can be given seperated by |. use ' marks to insure proper parameterization. can be used along-side of -excludedFiles
.PARAMETER excludedDirectoriesRegex
regular expression for excluding certain directories. multiple patterns can be given seperated by |. use ' marks to insure proper parameterization. can be used along-side of -excludedDirectories
#>
function Search {
    param(
    [Parameter(Mandatory)] [String] $pattern,
    [String] $rootPath = ".",
    [alias("in")] [Switch] $includeNodeModules,
    [alias("l")] [Switch] $includeLineText,
    [alias("if")] [String] $includedFiles = "",
    [alias("ef")] [String] $excludedFiles = "",
    [alias("ed")] [String] $excludedDirectories = "",
    [alias("f")] [Switch] $flat = $false,
    [alias("ifr")] [String] $includedFilesRegex = "",
    [alias("efr")] [String] $excludedFilesRegex = "",
    [alias("edr")] [String] $excludedDirectoriesRegex = ""
    )

    $ifArg = @()
    if($includedFiles -ne "")
    {
        Write-Verbose "beginning to parse included files parameter"
        Write-Verbose "args: $($includedFiles)"
        $includedFiles = $includedFiles -replace '\.','\.'
        Write-Verbose "period regex: $($includedFiles)"
        $includedFiles = $includedFiles -replace '\*','.*?'
        Write-Verbose "wild card regex: $($includedFiles)"
        $ifArg += $includedFiles.Split('|');
        for($i=0; $i -lt $ifArg.Length; $i++) { $ifArg[$i] = '^' + $ifArg[$i] + '$' }
        Write-Verbose "Final Array of Included Files:"
        foreach($i in $ifArg) { Write-Verbose $i }
    }
    if($includedFilesRegex -ne "")
    {
        Write-Verbose "beginning to parse included files regex parameter"
        $ifArg += $includedFilesRegex.Split('|');
        Write-Verbose "Final Array of Included Files:"
        foreach($i in $ifArg) { Write-Verbose $i }
    }
    $efArg = @()
    if($excludedFiles -ne "")
    {
        Write-Verbose "beginning to parse excluded files parameter"
        Write-Verbose "args: $($excludedFiles)"
        $excludedFiles = $excludedFiles -replace '\.','\.'
        Write-Verbose "period regex: $($excludedFiles)"
        $excludedFiles = $excludedFiles -replace '\*','.*?'
        Write-Verbose "wild card regex: $($excludedFiles)"
        $efArg = $excludedFiles.Split('|');
        for($i=0; $i -lt $efArg.Length; $i++) { $efArg[$i] = '^' + $efArg[$i] + '$' }
        Write-Verbose "Final Array of Excluded Files:"
        foreach($i in $efArg) { Write-Verbose $i }
    }
    if($excludedFilesRegex -ne "")
    {
        Write-Verbose "beginning to parse excluded files regex parameter"
        $efArg += $excludedFilesRegex.Split('|');
        Write-Verbose "Final Array of Excluded Files:"
        foreach($i in $efArg) { Write-Verbose $i }
    }
    $edArg = @()
    if($excludedDirectories -ne "")
    {
        if(-Not $includeNodeModules) { Write-Verbose "appending node_modules to list of excluded directories"
            $excludedDirectories += '|node_modules' }
        Write-Verbose "beginning to parse excluded directories parameter"
        Write-Verbose "args: $($excludedDirectories)"
        $excludedDirectories = $excludedDirectories -replace '\*','.*?'
        Write-Verbose "wild card regex: $($excludedDirectories)"
        $edArg = $excludedDirectories.Split('|');
        for($i=0; $i -lt $edArg.Length; $i++) { $edArg[$i] = '^' + $edArg[$i] + '$' }
        Write-Verbose "Final Array of Excluded Directories:"
        foreach($i in $edArg) { Write-Verbose $i }
    }
    else
    {
        if(-Not $includeNodeModules) 
        { 
            Write-Verbose "appending node_modules to list of excluded directories"
            $edArg += @('^node_modules$') 
            Write-Verbose "Final Array of Excluded Directories:"
            foreach($i in $edArg) { Write-Verbose $i }
        }
    }
    if($excludedDirectoriesRegex -ne "")
    {
        Write-Verbose "beginning to parse excluded directories regex parameter"
        $edArg += $excludedDirectoriesRegex.Split('|');
        Write-Verbose "Final Array of Excluded Directories:"
        foreach($i in $edArg) { Write-Verbose $i }
    }
    Push-Location $rootPath
    Write-Verbose "Invoking GetFiles"
    $collection = GetFiles . $ifArg $efArg $flat $edArg
    Write-Verbose "Collection Built"
    $prog = 0
    $total = $collection.Length
    Write-Verbose " "
    Write-Verbose "Beginning Search..."
    foreach($file in $collection) 
    {
        Write-Verbose ">Checking $($file) for matches..."
        $percent = [math]::Round($prog / $total * 100,2)
        Write-Progress -Activity "Search in Progress" -Status "$percent% Complete:" -PercentComplete $percent;
        foreach( $result in Select-String -Pattern $pattern -Path $file -AllMatches)
        {
            Write-Verbose ">>Match found in $($file) on line $($result.LineNumber): $($result.Line.Trim())"
            if($includeLineText) { Write-Output "$(Resolve-Path -relative $file):$($result.LineNumber)   $($result.Line.Trim())" }
            else { Write-Output "$(Resolve-Path -relative $file):$($result.LineNumber)" }
        }
        $prog = $prog + 1;
    }
    Pop-Location
}

function GetFiles($path, $includedFiles, $excludedFiles, $runFlat, $excludedDirectories) {
    Write-Verbose " "
    Write-Verbose "┬GetFiles invoked for $($path)"
    $ifiles = $includedFiles.Length -gt 0
    $efiles = $excludedFiles.Length -gt 0
    $edirs = $excludedDirectories.Length -gt 0
    foreach($file in Get-ChildItem $path -File)
    {
        Write-Verbose "├┬Operating on file $($file)"
        if($ifiles)
        {
            foreach($f in $includedFiles)
            {
                if($file -match $f)
                {
                    Write-Verbose "│└─File $($file) matched to pattern $($f), returning file as result"
                    Write-Output $file.FullName
                    break
                }
                Write-Verbose "│└─File $($file) not matched, ignoring..."
            }
        }
        elseif($efiles)
        {
            $skip = 0
            foreach($f in $excludedFiles)
            {
                if($file -match $f)
                {
                    Write-Verbose "│└─File $($file) matched to pattern $($f), ignoring..."
                    $skip = 1
                    break
                }
            }
            if($skip -eq 0) 
            {
                Write-Verbose "│└─File $($file) no matches, returning file as result..."
                Write-Output $file.FullName 
            }
        }
        else
        {
            Write-Verbose "│└─File $($file) being returned as result..."
            Write-Output $file.FullName
        }
    }
    if(-Not $runFlat)
    {
        foreach($dire in Get-ChildItem $path -Directory)
        {
            Write-Verbose "├┬Operating on directory $($dire)"
            if ($edirs)
            {
                $skip = 0
                foreach($d in $excludedDirectories)
                {
                    if($dire -match $d)
                    {
                        Write-Verbose "│└─Directory $($dire) matched to pattern $($d), ignoring..."
                        $skip = 1
                        break
                    }
                }
                if($skip -eq 0) 
                {
                    Write-Verbose "│└─Directory $($dire) no matches, recursing..."
                    GetFiles $dire.FullName $includedFiles $excludedFiles $runFlat $excludedDirectories
                }
            }
            else
            {
                Write-Verbose "│└─Invoking Recursion on directory $($dire)..."
                GetFiles $dire.FullName $includedFiles $excludedFiles $runFlat $excludedDirectories
            }
        } #end directory
    }
} 

Set-Alias Investigate Search
#
# Cam2Web-Pwsh.ps1
#

$LogCommandHealthEvent = $True
$LogCommandLifecycleEvent = $True
$PSModuleAutoloadingPreference = 'All'
# SILENTLYCONTINUE, STOP, CONTINUE, INQUIRE, IGNORE, SUSPEND, or BREAK.
$DebugPreference = 'Continue'
$ErrorActionPreference = 'Continue'
$InformationPreference = 'Continue'
$ProgressPreference = 'Continue'
$VerbosePreference = 'Continue'
$WhatIfPreference = $False
$WarningPreference = 'Continue' # Enquire
<#
$PSDefaultParameterValues += @{"*:Debug"=$True}
$PSDefaultParameterValues += @{"*:Verbose"=$True}
$PSDefaultParameterValues += @{"*:Confirm"=$False}
#>

function Find-Cam2WebBinary {
    [OutputType([string])]

    $path = Join-Path -Path $Env:UserProfile -ChildPath 'cam2web.exe'
    $binary = Get-Item -LiteralPath $path
    return $binary;
}

$Script:process = $null;

function Start-Cam2Web {
    [OutputType([System.Diagnostics.Process])]
    param(

        [Parameter(Mandatory, HelpMessage = "File to an existing cam2web.cfg, usually in %USERPROFILE%\cam2web\")]
        [PSDefaultValue(Help = "%USERPROFILE%\cam2web\cam2web.cfg")]
        [ValidateScript({ Test-Path -Verbose:$true -Debug:$true -PathType Leaf -LiteralPath "$_" })]
        [string]$ConfigFilePath = "$Env:UserProfile\cam2web\cam2web.cfg",

        [Parameter(HelpMessage = "Automatically start streaming.")]
        [switch]$AutoStart,

        [Parameter(HelpMessage = "Start minimized.")]
        [switch]$StartHidden

    )

    $binary = Find-Cam2WebBinary

    $arguments = @(
        "/fcfg:`"$ConfigFilePath`""
    )

    if ( $AutoStart) {
        $arguments += "/start";
    }

    if ($StartHidden) {
        $arguments += "/noui";
        $arguments += "/minimize";
    }

    $processOptions = @{
        FilePath     = $binary
        ArgumentList = $arguments
        #RedirectStandardInput  = "TestSort.txt"
        #RedirectStandardOutput = "Sorted.txt"
        #RedirectStandardError  = "SortError.txt"
        #UseNewEnvironment      = $true

    }

    if($StartHidden) {
        $Script:process = Start-Process @processOptions -WindowStyle Hidden -PassThru -Verbose:$true -Debug:$true
    } else {
        $Script:process = Start-Process @processOptions -PassThru -Verbose:$true -Debug:$true
    }

    return $Script:process;
}

function Try-GetLocalActiveEndPoint {
    [OutputType([string])]
    $address = Get-NetRoute | Where-Object -FilterScript { $_.NextHop -Ne "::" } | Where-Object -FilterScript { $_.NextHop -Ne "0.0.0.0" } | Where-Object -FilterScript { ($_.NextHop.SubString(0, 6) -Ne "fe80::") } | Sort-Object -Property RouteMetric | select -First 1 | Get-NetIPAddress | select IPAddress
    return $address.IPAddress.ToString()
}

function Stop-Cam2Web {
    [OutputType([int])]
    param(
        [Parameter(HelpMessage = "Force immediate termination.")]
        [switch]$Force
    )

    switch($Script:process.PriorityClass)
    {
        [System.Diagnostics.ProcessPriorityClass]::BelowNormal {
            Write-Debug -Message "BelowNormal"
        }
        [System.Diagnostics.ProcessPriorityClass]::Idle {
            Write-Debug -Message "Idle" + $Script:process.PriorityClass.ToString()
        }
    }
    
    # Set priority normal, (not tested if) low priority can take its time on a busy system.
    $Script:process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal;
    
    if ( $Force ) {
        $Script:process.Kill();
    } else {
        if( -not($Script:process.CloseMainWindow()) -and -not($Script:process.WaitForExit(500)) )
        {
            Write-Debug -Message "No main window to close or system is really slow; user wanted to stop; using -Force to make it so."
            $Script:process.Kill();
        } else {
            Write-Debug -Message "Unexpected condition; user wanted to stop; using -Force to make it so."
            $Script:process.Kill();
        }
    }

    while(-not($Script:process.HasExited) ) {
        $Script:process.WaitForExit(60)
    }

    $retval = $Script:process.ExitCode
    # Cleanup state.
    $Script:process.Close()
    $Script:process = $null;
    return $retval;
}

function Get-Cam2WebUrl {

    [Uri]$uri = $null;
    if ( -not($Script:process) ) {
        # Sourcing this file after Start-Cam2Web resets script scope.
    } else {
        $Script:process.WaitForInputIdle(5000);

        $ip = Try-GetLocalActiveEndPoint
        #[Uri]$uri = ("http://{0}:{1}" -f $ip, $net.LocalPort)

        # TODO: Forever-loop.
        $net = $null;
        while (-not($net)) {
            try {
                $net = Get-NetTCPConnection -OwningProcess $Script:process.Id
                break;
            } catch {
                # Assuming timing issue, calling this with PID before port is bound causes exception.
            }
        }

        [Uri]$uri = ("http://{0}:{1}" -f $ip, $net.LocalPort)
    }

    return $uri.AbsoluteUri
}

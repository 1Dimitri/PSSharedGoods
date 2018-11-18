function Format-Stream {
    [alias('FTV','Format-TableVerbose','Format-TableDebug','Format-TableInformation','Format-TableWarning')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 1)][object] $InputObject,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 0)][Object[]] $Property,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 2)][Object[]] $ExcludeProperty,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 3)][switch] $HideTableHeaders,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 4)][int] $ColumnHeaderSize,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 5)][switch] $AlignRight,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 6)]
        [validateset('Output','Host','Warning','Verbose','Debug','Information')]
        [string] $Stream = 'Verbose'
    )
    Begin {
        $IsVerbosePresent = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

        if ($Stream -eq 'Output') {
            #
        } elseif ($Stream -eq 'Host') {
            #
        } elseif ($Stream -eq 'Warning') {
            [System.Management.Automation.ActionPreference] $WarningCurrent = $WarningPreference
            $WarningPreference = 'continue'
        } elseif ($Stream -eq 'Verbose') {
            [System.Management.Automation.ActionPreference] $VerboseCurrent = $VerbosePreference
            $VerbosePreference = 'continue'
        } elseif ($Stream -eq 'Debug') {
            [System.Management.Automation.ActionPreference] $DebugCurrent = $DebugPreference
            $DebugPreference = 'continue'
        } elseif ($Stream -eq 'Information') {
            [System.Management.Automation.ActionPreference] $InformationCurrent = $InformationPreference
            $InformationPreference = 'continue'
        }

        [bool] $FirstRun = $True # First run for pipeline
        [bool] $FirstLoop = $True # First loop for data
        [int] $ScreenWidth = $Host.UI.RawUI.WindowSize.Width - 12 # Removes 12 chars because of VERBOSE: output
        $ArrayList = @()
    }
    Process {
        if ((Get-ObjectCount -Object $InputObject) -eq 0) { break }
        if ($FirstRun) {
            $FirstRun = $false
            $Data = Format-PSTable -Object $InputObject -Property $Property -ExcludeProperty $ExcludeProperty -NoAliasOrScriptProperties:$NoAliasOrScriptProperties -DisplayPropertySet:$DisplayPropertySet -PreScanHeaders:$PreScanHeaders
            $Headers = $Data[0]
            if ($HideTableHeaders) {
                $Data.RemoveAt(0);
            }
            $ArrayList += $Data
        } else {
            $Data = Format-PSTable -Object $InputObject -Property $Property -ExcludeProperty $ExcludeProperty -NoAliasOrScriptProperties:$NoAliasOrScriptProperties -DisplayPropertySet:$DisplayPropertySet -PreScanHeaders:$PreScanHeaders -OverwriteHeaders $Headers -SkipTitle
            $ArrayList += $Data
        }
    }
    End {
        if (-not $ColumnHeaderSize) {
            $ColumnLength = [int[]]::new($Headers.Count);
            foreach ($Row in $ArrayList) {
                $i = 0
                foreach ($Column in $Row) {
                    $Length = "$Column".Length
                    if ($Length -gt $ColumnLength[$i]) {
                        $ColumnLength[$i] = $Length
                    }
                    $i++
                }
            }
            if ($IsVerbosePresent) {
                Write-Verbose "Format-TableVerbose - ScreenWidth $ScreenWidth"
                Write-Verbose "Format-TableVerbose - Column Lengths $($ColumnLength -join ',')"
            }
        }
        # Add empty line
        if ($Stream -eq 'Output') {
            Write-Output -InputObject ''
        } elseif ($Stream -eq 'Host') {
            Write-Host -Object ''
        } elseif ($Stream -eq 'Warning') {
            Write-Warning -Message ''
        } elseif ($Stream -eq 'Verbose') {
            Write-Verbose -Message ''
        } elseif ($Stream -eq 'Debug') {
            Write-Debug -Message ''
        } elseif ($Stream -eq 'Information') {
            Write-Information -MessageData ''
        }
        # Process Data
        foreach ($Row in $ArrayList ) {
            [string] $Output = ''
            [int] $ColumnNumber = 0
            [int] $CurrentColumnLength = 0
            # Prepare each data for row
            foreach ($ColumnValue in $Row) {

                # Set Column Header Size to static value or based on string length
                if ($ColumnHeaderSize) {
                    $PadLength = $ColumnHeaderSize + 1 # Add +1 to make sure there's space between columns
                } else {
                    $PadLength = $ColumnLength[$ColumnNumber] + 1 # Add +1 to make sure there's space between columns
                }

                # Makes sure to display all data on current screen size, the larger the screen, the more it fits
                $CurrentColumnLength += $PadLength
                if ($CurrentColumnLength -ge $ScreenWidth) {
                    break
                }

                # Prepare Data
                $ColumnValue = ("$ColumnValue".ToCharArray() | Select-Object -First ($PadLength)) -join ""
                if ($Output -eq '') {
                    if ($AlignRight) {
                        $Output = "$ColumnValue".PadLeft($PadLength)
                    } else {
                        $Output = "$ColumnValue".PadRight($PadLength)
                    }
                } else {
                    if ($AlignRight) {
                        $Output = $Output + "$ColumnValue".PadLeft($PadLength)
                    } else {
                        $Output = $Output + "$ColumnValue".PadRight($PadLength)
                    }
                }
                $ColumnNumber++
            }
            if ($Stream -eq 'Output') {
                Write-Output -InputObject $Output
            } elseif ($Stream -eq 'Host') {
                Write-Host -Object $Output
            } elseif ($Stream -eq 'Warning') {
                Write-Warning -Message $Output
            } elseif ($Stream -eq 'Verbose') {
                Write-Verbose -Message $Output
            } elseif ($Stream -eq 'Debug') {
                Write-Debug -Message $Output
            } elseif ($Stream -eq 'Information') {
                Write-Information -MessageData $Output
            }


            if (-not $HideTableHeaders) {
                # Add underline
                if ($FirstLoop) {
                    $HeaderUnderline = $Output -Replace '\w', '-'
                    #Write-Verbose -Message $HeaderUnderline
                    if ($Stream -eq 'Output') {
                        Write-Output -InputObject $HeaderUnderline
                    } elseif ($Stream -eq 'Host') {
                        Write-Host -Object $HeaderUnderline
                    } elseif ($Stream -eq 'Warning') {
                        Write-Warning -Message $HeaderUnderline
                    } elseif ($Stream -eq 'Verbose') {
                        Write-Verbose -Message $HeaderUnderline
                    } elseif ($Stream -eq 'Debug') {
                        Write-Debug -Message $HeaderUnderline
                    } elseif ($Stream -eq 'Information') {
                        Write-Information -MessageData $HeaderUnderline
                    }
                }
            }

            $FirstLoop = $false
        }

        # Add empty line
        if ($Stream -eq 'Output') {
            Write-Output -InputObject ''
        } elseif ($Stream -eq 'Host') {
            Write-Host -Object ''
        } elseif ($Stream -eq 'Warning') {
            Write-Warning -Message ''
        } elseif ($Stream -eq 'Verbose') {
            Write-Verbose -Message ''
        } elseif ($Stream -eq 'Debug') {
            Write-Debug -Message ''
        } elseif ($Stream -eq 'Information') {
            Write-Information -MessageData ''
        }


        # Set back to defaults
        if ($Stream -eq 'Output') {
            #
        } elseif ($Stream -eq 'Host') {
            #
        } elseif ($Stream -eq 'Warning') {
            $WarningPreference = $WarningCurrent
        } elseif ($Stream -eq 'Verbose') {
            $VerbosePreference = $VerboseCurrent
        } elseif ($Stream -eq 'Debug') {
            $DebugPreference = $DebugCurrent
        } elseif ($Stream -eq 'Information') {
            $InformationPreference = $InformationCurrent
        }
    }
}
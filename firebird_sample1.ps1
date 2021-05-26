#Define variable for echo exicution status if error with step number in algorithm
$step = 1

#Define date/time for adding to the end of remote archive directory
$timeStamp = get-date -f yyyyMMddhhmm

#Define path to local backup folder
$localBackupDirectory = "C:\Windows\Temp\fbackup"

#Define remote path to backup folder after mounting as S:\
$remoteBackupDirectory = "S:\fbackup_" + $TimeStamp

#Define condition to execute main algorithm in script body 
$executionCondition = $true

#Define boolean value to execute step 1
$isLocalBackupDirectoryExist = Test-Path -Path $localBackupDirectory

#Define initial status of main algorithm result value (also to prevent incorrect execution in following algorithm)
$mainStatus = $false

#Define path to gbak binary file for step 2
$gbakPath = "C:\Program Files (x86)\Кольпоскопия ZMIR\Firebird21\bin\gbak.exe"

#main algorithm
$mainStatus = :execution while($executionCondition) {

    #step 1
    $step1 = if ($isLocalBackupDirectoryExist) { 
        
        #Recreate local backup directory to prevent unexpected errors (e.g. if it contains previous backup files)
        Remove-Item $localBackupDirectory
        New-Item -ItemType Directory -Path $localBackupDirectory
        Write-Host "Local backup directory already existed but was recreated sucsessfully"
        $isLocalBackupDirectoryExist = $true
        $step++
         
    } elseif ($isLocalBackupDirectoryExist -eq $false) { 
    
        New-Item -ItemType Directory -Path $localBackupDirectory
        Write-Host "Backup directory doesn't exist and was created sucsessfully"
        $isLocalBackupDirectoryExist = $true
        $step++

    } else {
    
         if ($isLocalBackupDirectoryExist -eq $false) {

        Write-Host "Can't recreate $localBackupDirectory"
        break :execution
        }
    }

    $step2 = if ($step -eq 2) {

        $gbakExec = Start-Process -FilePath $gbakPath -ArgumentList "-backup `"C:\Program Files (x86)\Кольпоскопия ZMIR\KPSBASE.FDB`" `"C:\Windows\Temp\fbackup\KPSBASE.FBK`"  -user SYSDBA -password masterkey -y `"C:\Windows\Temp\fbackup\KPSBASE.log`" -v" -PassThru -wait

        if($gbakExec.ExitCode -eq 0) {

             Write-Host "Gbak executed sucsessfully"
             $step++

        } else {

              Write-Host "Gbak wasn't executed"
              $executionCondition = $false
              break :execution
        }
  
    }

    $step3 = if ($step2) {

        try {    
            
            New-SmbMapping -LocalPath 'S:' -RemotePath "\\GRANDSERVER3\Share\backup\406" -UserName "username" -Password "password"

            }

        catch {
         
            Write-Host "There was an error mapping S: to \\GRANDSERVER3\Share\backup\406"
            $executionCondition = $false
            break :execution

            }

     }
    
    $step4 = if ($step3) {

        New-Item -ItemType directory -Path $remoteBackupDirectory -Force
        Write-Host "$remoteBackupDirectory was created sucsessfuly"

    } else {

        Write-Host "Can't create $remoteBackupDirectory directory"
        $executionCondition = $false
        break :execution
    }

    $step5 = if ($step4) {

        Copy-Item -Path $localBackupDirectory\*.* -Destination $remoteBackupDirectory -Force
        Write-Host "Copying to $remoteBackupDirectory was sucsessfully"

    } else {

        Write-Host "Cant' copy files from $localBackupDirectory to $remoteBackupDirectory"
        $executionCondition = $false
        break :execution
    }

    $step6 = if ($step5) {

        Get-ChildItem -Path $localBackupDirectory -Include *.* -File -Recurse | foreach { $_.Delete()}
        Write-Host "$localBackupDirectory was cleanup sucsessfuly"

    } else {

        Write-Host "Cant't cleanup $localBackupDirectory directory"
        $executionCondition = $false
        break :execution
    }


}

if($status) {

    Write-Host "Execution was sucsessful"

} else {

    Write-Host "Execution failed on $step step"
    $executionCondition = $false
}

## PS > .\RegisterGateway.ps1  gatewayKey -IsRegisterOnRemoteMachine true
## if IsRegisterOnRemoteMachine = false, that means register the agent on local machine, otherwise, it will register on remote machine.

param
(
   $gatewayKey = $(throw "Please input the gatewayKey to register gateway."),
   $IsRegisterOnRemoteMachine = $false
)

$newRegistryPath = "Software\Microsoft\DataTransfer\DataManagementGateway\ConfigurationManager"
$oldRegistryPath = "Software\Microsoft\DataTransfer\DataManagementGateway\HostService\Hdis"
$DiacmdPath = "DiacmdPath"
$ServiceDLLPath = "ServiceDll"
$GatewayPluginAssemblyName = "Microsoft.Hdis.AgentPlugin.AgentManagement.dll"
$GatewayPluginTypeName = "Microsoft.Hdis.AgentPlugin.AgentManagement.AgentManagementObject"

function Get-InstalledFilePath
{
   $value = $null
   $newRegistryKey = $null
   $oldRegistryKey = $null

   $OSVersion =(Get-WmiObject Win32_OperatingSystem -computername $computerName).OSArchitecture
   
   if($OSVersion -eq '64-bit')
   {
      $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
      $newRegistryKey = $baseKey.OpenSubKey($newRegistryPath)
	  $oldRegistryKey = $baseKey.OpenSubKey($oldRegistryPath)
   }
   else
   {
      $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)
	  $newRegistryKey = $baseKey.OpenSubKey($newRegistryPath)
      $oldRegistryKey = $baseKey.OpenSubKey($oldRegistryPath)
   }
   
   if($newRegistryKey -ne $null)
   {
      $value = $newRegistryKey.GetValue($DiacmdPath)
   }
   if($value -eq $null -and $oldRegistryKey -ne $null)
   {
      ## This part is just used to keep the backward compatible for the released gateway (version from 1.0 ~ 1.2). 
      $value = $oldRegistryKey.GetValue($ServiceDLLPath)
	  $global:IsReleasedAgent = $true
   }
   return $value
}

function RegisterOneAgent()
{
    if($IsRegisterOnRemoteMachine -eq $false)
	{
	    $filePath = Get-InstalledFilePath
		
		if ($filePath -eq $null)
        {
            Write-host "Please install the agent first, then you can register it!"
            return
        }
		
		if($global:IsReleasedAgent -eq $true)
		{
			$fileDirectoryName = [System.IO.Path]::GetDirectoryName($filePath)
		    $gatewayPluginPath = [System.IO.Path]::Combine($fileDirectoryName, $GatewayPluginAssemblyName)
            $gatewayPluginAssembly = [Reflection.Assembly]::LoadFrom($gatewayPluginPath)
            $gatewayPlugin = $gatewayPluginAssembly.CreateInstance($GatewayPluginTypeName)
			
            try
            {
			   $gatewayPlugin.RegisterAgent($gatewayKey) | Out-File temp.txt
            }
            catch
		    {
		       ## Try to get detailed info when register agent failed
		       if($_.Exception.InnerException)
		       {
		          foreach($except in $_.Exception.InnerException.InnerExceptions)
			      {
			         $except.Message >> temp.txt
			      }
		       }
		       else
		       {
		          Write-host $_.Exception.Message >> temp.txt
		       }
		    }
		}
		else
		{
            &$filePath -k $gatewayKey | Out-File temp.txt
		}

        $result = Get-Content temp.txt

        if($result -eq $null)
        {
		    Restart-Service DIAHostService -WarningAction:SilentlyContinue
            Write-host "Agent registration is successful!"
        }
        else
        {
            Write-host "Agent registration has failed with below : $result"
        }

        Remove-Item temp.txt
	}
	else
	{
	    $session= New-PSSession -ComputerName $computerName -Credential $credential
		Invoke-Command -Session $session -ScriptBlock{ 
		   param($gatewayKey, $newRegistryPath, $oldRegistryPath, $DiacmdPath, $ServiceDLLPath, $GatewayPluginAssemblyName, $GatewayPluginTypeName)
		   
		   $filePath = $null
		   $IsReleasedAgent = $false
			
		   $newRegistryKey = $null
		   $oldRegistryKey = $null
		   
           $computerName = $env:COMPUTERNAME
		   $OSVersion =(Get-WmiObject Win32_OperatingSystem -computername $computerName).OSArchitecture
		   
		   if($OSVersion -eq '64-bit')
		   {
			  $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
			  $newRegistryKey = $baseKey.OpenSubKey($newRegistryPath)
			  $oldRegistryKey = $baseKey.OpenSubKey($oldRegistryPath)
		   }
		   else
		   {
			  $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)
			  $newRegistryKey = $baseKey.OpenSubKey($newRegistryPath)
			  $oldRegistryKey = $baseKey.OpenSubKey($oldRegistryPath)
		   }
		   
		   if($newRegistryKey -ne $null)
		   {
			  $filePath = $newRegistryKey.GetValue($DiacmdPath)
		   }
		   if($filePath -eq $null -and $oldRegistryKey -ne $null)
		   {
			  $filePath = $oldRegistryKey.GetValue($ServiceDLLPath)
	          $IsReleasedAgent = $true
		   }
		
		   if ($filePath -eq $null)
		   {
			   Write-host "Please install the agent first, then you can register it!"
			   return
		   }

		   if($IsReleasedAgent -eq $true)
		   {
				$fileDirectoryName = [System.IO.Path]::GetDirectoryName($filePath)
				$gatewayPluginPath = [System.IO.Path]::Combine($fileDirectoryName, $GatewayPluginAssemblyName)
				$gatewayPluginAssembly = [Reflection.Assembly]::LoadFrom($gatewayPluginPath)
				$gatewayPlugin = $gatewayPluginAssembly.CreateInstance($GatewayPluginTypeName)
				
				try
                {
			       $gatewayPlugin.RegisterAgent($gatewayKey) | Out-File temp.txt
                }
                catch
		        {
		           if($_.Exception.InnerException)
		           {
		              foreach($except in $_.Exception.InnerException.InnerExceptions)
			          {
			             $except.Message >> temp.txt
			          }
		           }
		           else
		           {
		              Write-host $_.Exception.Message >> temp.txt
		           }
		        }
		   }
		   else
		   {
				&$filePath -k $gatewayKey | Out-File temp.txt
		   }

		   $result = Get-Content temp.txt

		   if($result -eq $null)
		   {
				Restart-Service DIAHostService -WarningAction:SilentlyContinue
				Write-host "Agent registration is successful!"
		   }
		   else
		   {
				Write-host "Agent registration has failed with below : $result"
		   }
		   
		   Remove-Item temp.txt
        } -ArgumentList $gatewayKey, $newRegistryPath, $oldRegistryPath, $DiacmdPath, $ServiceDLLPath, $GatewayPluginAssemblyName, $GatewayPluginTypeName

        Remove-PSSession -Session $session
	}
}

$computerName= $env:COMPUTERNAME
$credential=""
$global:IsReleasedAgent = $false

if($IsRegisterOnRemoteMachine -eq $false)
{
    RegisterOneAgent
}
else
{
   $computerName = Read-Host "please specify a computer name:"
   $credential = Read-Host "please give the credential(domainName\userName) to get access to the remote computer:"
   RegisterOneAgent
}

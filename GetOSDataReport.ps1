##################################
## Powershell - Report OS ##
##################################
# Script for read data on all istances
# Import Module
Import-Module .\Modules\Module-Database.psm1 -Force
Import-Module .\Modules\Module-Xml.psm1 -Force
Import-Module .\Modules\Module-Log.psm1 -Force

# -- Custom Variables --
# Define variables
$strRootPath = Split-Path -Path $MyInvocation.MyCommand.Path
$strServersListPath = "$strRootPath\Sources\"
$strLogPath = "$strRootPath\Log\"
$intQueryTimeout = 20;
$strDateNow=Get-Date -format "yyyyMMdd"
$strServerName = "";
$strErrorMsg = "";

# Read Xml file config
$objXmlConf = ReadAllXmlFile -FilePath "$strRootPath\Config\ConfigOS.xml"

# Set variable after read config Xml
$strServersListFile = ("{0}\{1}" -f $strServersListPath, $objXmlConf.ConfigFile.SourceList.FileName)
$strLogFileName = ("{0}_{1}" -f $strDateNow, $objXmlConf.ConfigFile.LogInfo.FileName)
$strLogFile = ("{0}\{1}" -f $strLogPath, $strLogFileName)

# Create Dataset
$objDataset = New-Object System.Data.DataSet

# Volume Space
# Create DataTable for input data
$objDTVolumes = New-Object System.Data.DataTable("VolumesSpace")

# Set DataColumns for DataTable
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "RegDate") )
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "ServerName") )
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "DiskName") )
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "Size") )
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "FreeSpace") )

# Services
# Create DataTable for input data
$objDTServices = New-Object System.Data.DataTable("ServicesStatus")

# Set DataColumns for DataTable
$objDTServices.columns.Add( (New-Object System.Data.DataColumn "RegDate") )
$objDTServices.columns.Add( (New-Object System.Data.DataColumn "ServerName") )
$objDTServices.columns.Add( (New-Object System.Data.DataColumn "ServiceName") )
$objDTServices.columns.Add( (New-Object System.Data.DataColumn "DisplayName") )
$objDTServices.columns.Add( (New-Object System.Data.DataColumn "Status") )
$objDTServices.columns.Add( (New-Object System.Data.DataColumn "StartMode") )
$objDTServices.columns.Add( (New-Object System.Data.DataColumn "LogonAccount") )

# Open connection with destination database
$objSqlConnDest = OpenConnection -ServerName $objXmlConf.ConfigFile.DestInstance.ServerName -DatabaseName $objXmlConf.ConfigFile.DestInstance.DatabaseName

# Read file list
$arrServersList = Get-Content $strServersListFile

# Cycle of array for get values
foreach($strRow in $arrServersList)
{
	# Get server name
	$strServerName = $strRow
			
	#DEBUG
	Write-Debug $strServerName
		
	try
	{			
        # -- Volumes Space --    
        # Execute WMI query for check Volumes
		$objWmiVolumes = Get-WmiObject -Namespace "root\cimv2" -ComputerName $strServerName -Class Win32_LogicalDisk | 
			select Name, @{LABEL='Size(GB)';EXPRESSION={"{0:N2}" -f ($_.Size/1GB)} } , @{LABEL='FreeSpace(GB)';EXPRESSION={"{0:N2}" -f ($_.FreeSpace/1GB)} }, DriveType | Sort-Object Name	

		#DEBUG
		Write-Debug $objWmiVolumes.Count  
        		
		#Cycle for output
		foreach($objDisk in $objWmiVolumes)
		{
            # Check if disk is not removable
            if($objDisk.DriveType -ne 5)
            {
                # Output
                Write-Host ("{0} - {1} - {2} - {3}" -f $strServername, $objDisk.Name, $objDisk."Size(GB)", $objDisk."FreeSpace(GB)") 
            
                # Set new row
                $objDRowVolumes = $objDTVolumes.NewRow()
            
                # Add values to row
                $objDRowVolumes.RegDate = Get-Date
                $objDRowVolumes.ServerName = $strServername
                $objDRowVolumes.DiskName = $objDisk.Name
                $objDRowVolumes.Size = $objDisk."Size(GB)"
                $objDRowVolumes.FreeSpace = $objDisk."FreeSpace(GB)"

                # Add row
                $objDTVolumes.Rows.Add($objDRowVolumes)
            }
		}

        # -- Services Status --
        # Execute WMI query for check services
		$objWmiServices = Get-WmiObject -Namespace "root\cimv2" -ComputerName $strServerName -Class Win32_Service | 
			select Name, DisplayName, State, StartMode, StartName | 
            Where-Object { ($_.DisplayName -like "SQL Server*")} | Sort-Object Name	

        #Cycle for output
		foreach($objService in $objWmiServices)
		{
            # Output
            Write-Host ("{0} - {1} - {2} - {3} - {4} - {5}" -f $strServername, $objService.Name, $objService.DisplayName, $objService.State, $objService.StartMode, $objService.StartName)
            
            # Set new row
            $objDRowServices = $objDTServices.NewRow()

            # Add values to row
            $objDRowServices.RegDate = Get-Date
            $objDRowServices.ServerName = $strServername
            $objDRowServices.ServiceName = $objService.Name
            $objDRowServices.DisplayName = $objService.DisplayName
            $objDRowServices.Status = $objService.State
            $objDRowServices.StartMode = $objService.StartMode
            $objDRowServices.LogonAccount = $objService.StartName

            # Add row
            $objDTServices.Rows.Add($objDRowServices)             
		}        
	}
	catch
	{
		# Set error message		
        WriteErrorLog -FullPathLogFile $strLogFile -StringToWrite ("{0}: {1}" -f $strServername, $_.Exception.Message)
	}									

}	


try
{
    # -- Clean tables --
    # Define command text for delete old rows
    $strDelCommand = ("TRUNCATE TABLE {0}; TRUNCATE TABLE {1};" -f "DBREP.TB_VolumesSpaces", "DBREP.TB_Services")

    # Execute query for delete
    ExecuteNonQuery -SqlConnection $objSqlConnDest -CommandText $strDelCommand

    # -- Volumes Space --
    # Call method for insert data
    ExecuteBulk -SqlConnection $objSqlConnDest -DataTable $objDTVolumes -DestTableName "DBREP.TB_VolumesSpaces"

    # -- Services --
    # Call method for insert data
    ExecuteBulk -SqlConnection $objSqlConnDest -DataTable $objDTServices -DestTableName "DBREP.TB_Services"
}
catch
{
    # Set error message		
    WriteErrorLog -FullPathLogFile $strLogFile -StringToWrite ("{0}: {1}" -f "INSERT TABLE Problem", $_.Exception.Message)
}
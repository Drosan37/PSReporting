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

# Create DataTable for input data
$objDTVolumes = New-Object System.Data.DataTable("VolumesSpace")

# Set DataColumns for DataTable
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "RegDate") )
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "ServerName") )
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "DiskName") )
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "Size") )
$objDTVolumes.columns.Add( (New-Object System.Data.DataColumn "FreeSpace") )

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
        # Execute WMI query for check Volumes
		$objWmi = Get-WmiObject -Namespace "root\cimv2" -ComputerName $strServerName -Class Win32_LogicalDisk | 
			select Name, @{LABEL='Size(GB)';EXPRESSION={"{0:N2}" -f ($_.Size/1GB)} } , @{LABEL='FreeSpace(GB)';EXPRESSION={"{0:N2}" -f ($_.FreeSpace/1GB)} }, DriveType | Sort-Object Name	

		#DEBUG
		Write-Debug $objWmi.Count  
        		
		#Cycle for output
		foreach($strDisk in $objWmi)
		{
            # Check if disk is not removable
            if($strDisk.DriveType -ne 5)
            {
                # Output
                Write-Host ("{0} - {1} - {2} - {3}" -f $strServername, $strDisk.Name, $strDisk."Size(GB)", $strDisk."FreeSpace(GB)") 
            
                # Set new row
                $objDRow = $objDTVolumes.NewRow()
            
                # Add values to row
                $objDRow.RegDate = Get-Date
                $objDRow.ServerName = $strServername
                $objDRow.DiskName = $strDisk.Name
                $objDRow.Size = $strDisk."Size(GB)"
                $objDRow.FreeSpace = $strDisk."FreeSpace(GB)"

                # Add row
                $objDTVolumes.Rows.Add($objDRow)
            }
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
    # Define command text for delete old rows
    $strDelCommand = ("TRUNCATE TABLE {0}" -f "DBREP.TB_VolumesSpaces")

    # Execute query for delete
    ExecuteNonQuery -SqlConnection $objSqlConnDest -CommandText $strDelCommand

    # Call method for insert data
    ExecuteBulk -SqlConnection $objSqlConnDest -DataTable $objDTVolumes -DestTableName "DBREP.TB_VolumesSpaces"
}
catch
{
    # Set error message		
    WriteErrorLog -FullPathLogFile $strLogFile -StringToWrite ("{0}: {1}" -f "INSERT TABLE Problem", $_.Exception.Message)
}
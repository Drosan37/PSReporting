####################################
## Powershell - Report SQL Server ##
####################################
# Script for read data on all istances
# Import Module
Import-Module .\Modules\Module-Database.psm1 -Force
Import-Module .\Modules\Module-Xml.psm1 -Force
Import-Module .\Modules\Module-Log.psm1 -Force

# Define variables
$strRootPath = Split-Path -Path $MyInvocation.MyCommand.Path
$strInstancesListPath = "$strRootPath\Sources\"
$strLogPath = "$strRootPath\Log\"
$intQueryTimeout = 20;
$strDateNow = Get-Date -format "yyyyMMdd"
$strServerName = "";
$strErrorMsg = "";

# DEBUG
Write-Debug $strRootPath

# Read Xml file config
$objXmlConf = ReadAllXmlFile -FilePath "$strRootPath\Config\Config.xml"

# Set variable after read config Xml
$strInstancesListFile = ("{0}\{1}" -f $strInstancesListPath, $objXmlConf.ConfigFile.SourceList.FileName)
$strLogFileName = ("{0}_{1}" -f $strDateNow, $objXmlConf.ConfigFile.LogInfo.FileName)
$strLogFile = ("{0}\{1}" -f $strLogPath, $strLogFileName)

# Init file log
InitFileLog -PathLog $strLogPath -FileName $strLogFileName

# Read file list
$arrInstancesList = Get-Content $strInstancesListFile

# Open connection with destination database
$objSqlConnDest = OpenConnection -ServerName $objXmlConf.ConfigFile.DestInstance.ServerName -DatabaseName $objXmlConf.ConfigFile.DestInstance.DatabaseName 

# Cycle for all source instances
foreach($strInstance in $arrInstancesList)
{
    # DEBUG
    Write-Debug $strInstance

    try
    {
        # Open connection with source database
        $objSqlConnSource = OpenConnection -ServerName $strInstance
    }
    catch
    {
        # Write Log
        WriteErrorLog -FullPathLogFile $strLogFile -StringToWrite ("{0}: {1}" -f $strInstance, $_.Exception.Message)
        
        # Next row into source
        continue
    }

    # Cycle for all Type tag
    foreach($type in $objXmlConf.ConfigFile.DataGathering.ChildNodes)
    {
        # DEBUG
        Write-Debug ("{0} - {1}" -f $type.Query, $type.TableDest) 

        try
        {
            # Define sql command text (raw for get in one row)
            $strSqlCommandText = Get-Content ("$strRootPath\Queries\{0}" -f $type.Query) -Raw
        
            # Execute query for gather data
            $objDataTable = ExecuteReader -SqlConnection $objSqlConnSource -CommandText $strSqlCommandText

            # Check if option for delete old is true
            if($type.DeleteOld -eq "true")
            {
                # DEBUG
                Write-Debug "Delete Old option"

                # Define command text for delete old rows
                $strDelCommand = ("DELETE FROM {0} WHERE ComputerName = '{1}'" -f $type.TableDest, $strInstance)

                # Execute query for delete
                ExecuteNonQuery -SqlConnection $objSqlConnDest -CommandText $strDelCommand
            }

            # Call method for insert data
            ExecuteBulk -SqlConnection $objSqlConnDest -DataTable $objDataTable -DestTableName $type.TableDest

        }
        catch
        {
            # DEBUG 
            Write-Host $_.Exception
        }
    }

    # Close connection with source database
    CloseConnection $objSqlConnSource    
}

# Close connection with destination database
CloseConnection -SqlConnection $objSqlConnDest

# If log is empty, delete it
if([string]::IsNullOrWhiteSpace((Get-content ("{0}\{1}" -f $strLogPath, $strLogFileName)))) { Remove-Item -Path ("{0}\{1}" -f $strLogPath, $strLogFileName) }
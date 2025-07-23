# Script for gather information about disk size on all PROD servers
Import-Module SqlServer -Version 21.1.18209			
			
# ## Function to write error log
function WriteErrorLog
{
	# Function params
	param ( [string] $StringToWrite )

	# Write to file
	Add-Content -path $strErrorLogFile -value $StringToWrite
}	

# Set date now
$strDateNow = Get-Date -format "yyyyMMdd"

# Define the file path where server names are stored
$strErrorLogFile = ("<pathfile>\Logs\{0}_ErrorAGStatus.log" -f $strDateNow)

# Initialize variables	
$intQueryTimeout = 600;	

# Define query for retrieve server list
$strQueryServerList = ("    
    SELECT * FROM CHK.GetServerList  
    WHERE AGName IS NOT NULL 
") 

# Create an empty array to store the results
$diskInfo = @()

# Set culture for avoid problems with decimal
$culture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")

try		
{		
	# Execute query to retrieve server list	
	$arrServerList = Invoke-Sqlcmd $strQueryServerList -ServerInstance "<instance>,<port>" -Database "SqlServerMap" -QueryTimeout $intQueryTimeout -ErrorAction 'Stop';	
}		
catch		
{		
	# Set error message	
	$strErrorMsg = "ERROR on Execute query for retrieve server List:`r`n$($_.Exception.Message)"; 	
		
	# Write Error Log	
	WriteErrorLog $strErrorMsg;	
}

# Define string for query with Truncate for remove old data
$strQueryTruncate = "TRUNCATE TABLE [CHK].[AGStatus];"

try		
{		
	# Execute query to retrieve server list	
	Invoke-Sqlcmd $strQueryTruncate -ServerInstance "<instance>,<port>" -Database "<database>" -QueryTimeout $intQueryTimeout -ErrorAction 'Stop';	
}		
catch		
{		
	# Set error message	
	$strErrorMsg = "ERROR on Execute query for truncate table:`r`n$($_.Exception.Message)"; 	
		
	# Write Error Log	
	WriteErrorLog $strErrorMsg;	
}	

 # Define template of insert query
$strQuerySingleInsert = "INSERT INTO [CHK].[AGStatus] ([ReplicaServerName],[NodeRole],[Database],[IsSuspended],[SyncState],[SyncHealth],[LastSentTime],[LastRedoneTime],[RedoQueueSize(KB)],[RedoRate(KB/sec)],[EstimatedRedoTime(sec)])
    VALUES ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}');
"

# Create empty string that contains list of insert query for each instance
$strMultipleInsQueries = ""

# Loop through each server and retrieve disk space for mounted volumes
foreach ($server in $arrServerList) {
    # Define variable for each server
    $strServerName = $server.ServerName
    $strInstanceName = $server.InstanceName
    $strPortNumber = $server.PortNumber
    
    # Create empty string that contains list of insert query for each instance
    $strMultipleInsQueries = ""    

    $strQueryAGState = ("
        SELECT 
	          ar.replica_server_name AS ReplicaServerName
            , CASE 
		        WHEN ast.primary_replica = ar.replica_server_name THEN 'PRIMARY'
		        ELSE 'SECONDARY'
	          END AS NodeRole
	        , DB_NAME(drs.database_id) AS [Database]
            , drs.is_suspended AS [IsSuspended]
            , drs.synchronization_state_desc AS [SyncState]
            , drs.synchronization_health_desc AS [SyncHealth]
            , drs.last_sent_time AS LastSentTime    
            , drs.last_redone_time AS LastRedoneTime
	        , drs.redo_queue_size AS [RedoQueueSize(KB)]
            , drs.redo_rate AS [RedoRate(KB/sec)]
            , CASE 
                WHEN drs.redo_rate > 0 THEN drs.redo_queue_size / drs.redo_rate
                ELSE NULL
	          END AS [EstimatedRedoTime(sec)]	
        FROM 
            sys.dm_hadr_database_replica_states drs 
	        INNER JOIN sys.availability_replicas ar 
		        ON drs.replica_id = ar.replica_id
	        INNER JOIN sys.dm_hadr_availability_group_states ast
		        ON ar.group_id = ast.group_id
        WHERE ar.replica_server_name like '{0}\%'
    ") -f $strServerName

    try		
    {
        try
		{
			# Check if instance name is default
			if($strInstanceName -eq 'MSSQLSERVER')
			{
				# Execute query for retrieve information on SQL Server Version (try to use default port)									
				$drSqlAgStatus = Invoke-Sqlcmd $strQueryAGState -ServerInstance "$strServerName,1433" -QueryTimeout $intQueryTimeout -ErrorAction 'Stop';
			}
			else
			{			
				# Execute query for retrieve information on SQL Server Version									
				$drSqlAgStatus = Invoke-Sqlcmd $strQueryAGState -ServerInstance "$strServerName\$strInstanceName" -QueryTimeout $intQueryTimeout -ErrorAction 'Stop';
			}
		}
		catch
		{
			# Execute query for retrieve information on SQL Server Version									
			$drSqlAgStatus = Invoke-Sqlcmd $strQueryAGState -ServerInstance "$strServerName,$strPortNumber" -QueryTimeout $intQueryTimeout -ErrorAction 'Stop';
		}
        
    }
    
    catch		
    {		
	    # Set error message	
	    $strErrorMsg = "ERROR on Execute query for retrieve AG status for the server ${strServerName}:`r`n$($_.Exception.Message)"; 	
		
	    # Write Error Log	
	    WriteErrorLog $strErrorMsg;	
    }

    # Cycle for each row of datareader object
    foreach($objRow in $drSqlAgStatus)
    {
        # Add to multiple query string the single insert query
        $strMultipleInsQueries += ($strQuerySingleInsert -f $objRow.ReplicaServerName, $objRow.NodeRole, $objRow.Database, $objRow.IsSuspended, $objRow.SyncState, $objRow.SyncHealth,
            $objRow.LastSentTime, $objRow.LastRedoneTime, $objRow['RedoQueueSize(KB)'], $objRow['RedoRate(KB/sec)'], $objRow['EstimatedRedoTime(sec)'])
    }

    #DEBUG
    #Write-Host $strMultipleInsQueries

    try		
    {		
	    # Execute query to retrieve server list	
	    Invoke-Sqlcmd -Query $strMultipleInsQueries -ServerInstance "<instance>,<port>" -Database "<database>" -QueryTimeout $intQueryTimeout -ErrorAction 'Stop';
    
    }		
    catch		
    {		
	    # Set error message	
	    $strErrorMsg = "ERROR on Execute query for insert data:`r`n$($_.Exception.Message)"; 	
		
	    # Write Error Log	
	    WriteErrorLog $strErrorMsg;	
    }
}

# Display confirmation message
Write-Host "Availability Group status report saved to Database <database> on <instance>"

##############################################
## Powershell Module for Database Functions ##
##############################################
function OpenConnection {
    param(
        [Parameter(Mandatory)]
        [string]$ServerName,

        [string]$DatabaseName = 'master'
    )

    # Set connection string (trusted auth)
    $strConnString = 'Data Source={0};database={1};Trusted_Connection=True;' -f $ServerName, $DatabaseName

    # Create object connection
    $objSqlConnection = New-Object System.Data.SqlClient.SqlConnection $strConnString
    
    try
    {    
        # Open connection
        $objSqlConnection.Open()    

        # Return SqlConnection
        return $objSqlConnection
    }
    catch [System.Data.SqlClient.SqlException] 
    {
        # DEBUG
        Write-Debug $_.Exception

        # Throw Exception
        throw
    }
}

function CloseConnection {
    param(
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$SqlConnection
    )

    # Close connection (object passed) and dispose
    $SqlConnection.Close()
    $SqlConnection.Dispose()

    # Forse Garbage Collector
    [System.GC]::Collect()    
}

function ExecuteReader {
    param(
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$SqlConnection,

        [Parameter(Mandatory)]
        [string]$CommandText
    )
    
    try {		
        # Create object SqlCommand		
		$objSqlcommand = New-Object System.Data.Sqlclient.Sqlcommand($CommandText,$SqlConnection)
        $objSqlcommand.CommandTimeout = 600
		
        # Create object SqlAdapter		
		$objSqlAdapter = New-Object System.Data.Sqlclient.SqlDataAdapter $objSqlcommand
		
        # Create object Dataset    
        $objDataset = New-Object System.Data.DataSet
		
        # Execute query and fill dataset (out-null avoid record number print)
        $objSqlAdapter.Fill($objDataset) | Out-Null
		
        # Return DataTable
		return $objDataset.Tables 				
    } 
    catch [System.Data.SqlClient.SqlException] {
        # DEBUG
        Write-Debug $_.Exception.Message
    
        # Throw Exception
        throw
    }
    finally {
        
    }
}

function ExecuteBulk {
    param(
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$SqlConnection,

        [Parameter(Mandatory)]
        [System.Data.DataTable]$DataTable,

        [Parameter(Mandatory)]
        [string]$DestTableName
    )

    try {		
        # Create object SqlBulk
		$objSqlBulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy $SqlConnection

        # Set destination table
        $objSqlBulkCopy.DestinationTableName = $DestTableName
        
        # Execute bulk insert, with datatable data
        $objSqlBulkCopy.WriteToServer($DataTable)
    } catch [System.Data.SqlClient.SqlException] {
        # DEBUG
        Write-Debug $_.Exception.Message

        # Throw Exception
        throw
    } finally {

    }
}

function ExecuteNonQuery {
    param(
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$SqlConnection,

        [Parameter(Mandatory)]
        [string]$CommandText
    )
    
    try {		
        # Create object SqlCommand		
		$objSqlcommand = New-Object System.Data.Sqlclient.Sqlcommand($CommandText,$SqlConnection)
		
        # Execute query 
        $objSqlcommand.ExecuteNonQuery() | Out-nUll			
    } catch [System.Data.SqlClient.SqlException] {
        # DEBUG
        Write-Debug $_.Exception.Message

        # Throw Exception
        throw
    } finally {
        
    }
}

# Export module
Export-ModuleMember -Function OpenConnection, CloseConnection
Export-ModuleMember -Function ExecuteReader, ExecuteBulk, ExecuteNonQuery
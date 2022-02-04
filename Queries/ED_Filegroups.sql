DECLARE @command NVARCHAR(4000) ;
DECLARE @OutputTable TABLE
(
	  DatabaseName VARCHAR(200) 
	, Filegroup VARCHAR(200) 
	, AllocatedSpace BIGINT 
	, SpaceUsed BIGINT
	, AvailableSpace BIGINT
	, MaxSpace BIGINT
	, SpaceUsedPercent BIGINT
);
BEGIN
SET @command = 'USE [?] ;' +
' SELECT' +
'   ''?'' AS DatabaseName' +
' 	, b.groupname AS ''Filegroup''' + 
' 	, a.AllocatedSpace' + 
' 	, a.SpaceUsed	' + 
' 	, a.AvailableSpace' + 
' 	, a.MaxSpace ' + 
' 	, CONVERT(INTEGER,ROUND((a.SpaceUsed/a.AllocatedSpace*100),0)) AS SpaceUsedPercent' + 
' FROM ' + 
' (' + 
' 	SELECT' + 
' 		  sf.groupid' + 
' 		, SUM(sf.AllocatedSpace) AS AllocatedSpace' + 
' 		, SUM(sf.SpaceUsed) AS SpaceUsed		' + 
' 		, SUM(sf.AvailableSpace) AS AvailableSpace' + 
' 		, SUM(sf.MaxSpace) AS MaxSpace ' + 
' 	FROM' + 
' 	(' + 
' 		SELECT ' + 
' 			  groupid' + 
' 			, name' + 
' 			, CONVERT(DECIMAL(15,2),ROUND(FILEPROPERTY(name,''SpaceUsed'')/128.000,2)) AS SpaceUsed' + 
' 			, CONVERT (Decimal(15,2),ROUND(size/128.000,2)) AS AllocatedSpace' + 
' 			, CONVERT (Decimal(15,2),ROUND((size-FILEPROPERTY(name,''SpaceUsed''))/128.000,2)) AS AvailableSpace' + 
' 			, CONVERT (Decimal(15,2),ROUND((' + 
' 				CASE maxsize' + 
' 					WHEN -1 THEN 0' + 
' 					ELSE maxsize' + 
' 				END)/128.000,2)) AS MaxSpace ' + 
' 		FROM sysfiles (NOLOCK)' + 
' 		WHERE groupid > 0' + 
' 	) sf' + 
' 	GROUP BY sf.groupid' + 
' ) a' + 
' JOIN sysfilegroups b (NOLOCK) ON a.groupid = b.groupid' +
' ORDER BY b.groupname; ' 

INSERT INTO @OutputTable
EXEC sp_MSforeachdb @command;

WITH cte AS
(
	SELECT		
		  tbl.*
		, row_number() OVER (ORDER BY tbl.AllocatedSpace DESC) AS Filtered
	FROM
	(
		SELECT 
			  DatabaseName
			, SUM(AllocatedSpace) AS AllocatedSpace
			, SUM(SpaceUsed) AS SpaceUsed
			, SUM(AvailableSpace) AS AvailableSpace				
		FROM @OutputTable
		GROUP BY DatabaseName
	) tbl
	WHERE DatabaseName NOT IN ('msdb','master','tempdb','model','distribution')
)

SELECT
		  GETUTCDATE() AS RegDate 
		, SERVERPROPERTY('MachineName') AS ComputerName	
	    , DatabaseName
		, AllocatedSpace
		, SpaceUsed
		, AvailableSpace
FROM
(
	SELECT 			
		  DatabaseName
		, AllocatedSpace
		, SpaceUsed
		, AvailableSpace
	FROM cte
	WHERE Filtered <= 10
	UNION ALL
	SELECT 
		  'Others' AS DatabaseName
		, SUM(AllocatedSpace) AS AllocatedSpace
		, SUM(SpaceUsed) AS SpaceUsed
		, SUM(AvailableSpace) AS AvailableSpace
	FROM
		cte
	WHERE filtered > 10
) tbl
ORDER BY AllocatedSpace DESC
END;

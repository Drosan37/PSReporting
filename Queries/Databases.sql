SELECT 
	  GETUTCDATE() AS RegDate
	, SERVERPROPERTY('MachineName') AS ComputerName
	, Name AS 'DatabaseName'
	, CASE compatibility_level
		WHEN 150 THEN 'SQL Server 2019'
		WHEN 140 THEN 'SQL Server 2017'
		WHEN 130 THEN 'SQL Server 2016'
		WHEN 120 THEN 'SQL Server 2014'	
		WHEN 110 THEN 'SQL Server 2012'
		WHEN 100 THEN 'SQL Server 2008'
		WHEN 90 THEN 'SQL Server 2005'
		WHEN 80 THEN 'SQL Server 2000'	
	END AS 'CompatibilityLevel'
	, collation_name AS 'CollationName'
	, CASE is_read_only
		WHEN 0 THEN 'FullAccess'
		WHEN 1 THEN 'ReadOnly'
	END AS ReadOnly
	, state_desc AS 'State'
	, recovery_model_desc AS 'RecoveryModel'
	, CASE is_auto_update_stats_on
		WHEN 0 THEN 'AutoUpdate Disabled'
		WHEN 1 THEN 'AutoUpdate Enabled'
	END AS StatisticsAutoUpdate
FROM sys.databases
WHERE
	name NOT IN ('master','model','msdb','tempdb');
USE [DB]
GO

/****** Object:  Table [CHK].[AGStatus]    Script Date: 7/23/2025 2:38:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--CREATE SCHEMA [CHK];

CREATE TABLE [CHK].[AGStatus](
	[ReplicaServerName] [nvarchar](256) NULL,
	[NodeRole] [varchar](9) NOT NULL,
	[Database] [nvarchar](128) NULL,
	[IsSuspended] [bit] NULL,
	[SyncState] [nvarchar](60) NULL,
	[SyncHealth] [nvarchar](60) NULL,
	[LastSentTime] [datetime] NULL,
	[LastRedoneTime] [datetime] NULL,
	[RedoQueueSize(KB)] [bigint] NULL,
	[RedoRate(KB/sec)] [bigint] NULL,
	[EstimatedRedoTime(sec)] [bigint] NULL,
	[Timestamp] [datetime] NULL
) ON [DBAdmin_Cold_FG_01]
GO

ALTER TABLE [CHK].[AGStatus] ADD  DEFAULT (getdate()) FOR [Timestamp]
GO

CREATE VIEW [CHK].[CheckAGStatusSync] AS 
SELECT 
	  UPPER([ReplicaServerName]) AS [ReplicaServerName]
	, [NodeRole]
    , [Database]
    , [IsSuspended]
    , [SyncState]
    , [SyncHealth]
    , CASE 
		WHEN [LastSentTime] = '1900-01-01 00:00:00.000' THEN NULL
		ELSE [LastSentTime]
	END AS [LastSentTime]
	, CASE 
		WHEN [LastRedoneTime] = '1900-01-01 00:00:00.000' THEN NULL
		ELSE [LastRedoneTime]
	END AS [LastRedoneTime]      
    , [RedoQueueSize(KB)]
    , [RedoRate(KB/sec)]
    , [EstimatedRedoTime(sec)]
	, [Timestamp]
FROM [DBAdmin].[CHK].[AGStatus]
GO


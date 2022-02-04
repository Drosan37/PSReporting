USE [DBA]
GO

/****** Object:  Table [dbo].[THC_Filegroups]    Script Date: 19/05/2021 14:54:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE SCHEMA DBREP

CREATE TABLE [DBREP].[TB_Filegroups](
	[RegDate] [DATETIME] NOT NULL,
	[ComputerName] [VARCHAR](255) NOT NULL,
	[DatabaseName] [VARCHAR](255) NULL,
	[AllocatedSpace] [BIGINT] NULL,
	[SpaceUsed] [BIGINT] NULL,
	[AvailableSpace] [BIGINT] NULL
) ON [Data]

CREATE TABLE [DBREP].[TB_Databases](
	[RegDate] [DATETIME] NOT NULL,
	[ComputerName] [VARCHAR](255) NOT NULL,
	[DatabaseName] [VARCHAR](255) NOT NULL,
	[CompatibilityLevel] [VARCHAR](100) NULL,
	[CollationName] [VARCHAR](255) NULL,
	[ReadOnly] [VARCHAR](10) NULL,
	[State] [VARCHAR](60) NULL,
	[RecoveryModel] [VARCHAR](60) NULL,
	[StatisticsAutoUpdate] [VARCHAR](20) NULL
) ON [Data]

CREATE TABLE [DBREP].[TB_Instances](
	[RegDate] [DATETIME] NOT NULL,
	[ComputerName] [VARCHAR](255) NOT NULL,
	[ProductVersion] [VARCHAR](255) NULL,
	[VersionName] [VARCHAR](20) NULL,
	[ProductLevel] [VARCHAR](255) NULL,
	[Edition] [VARCHAR](255) NULL,
	[ClusterMode] [VARCHAR](10) NULL,
	[AlwaysOnOption] [VARCHAR](30) NOT NULL,
	[SqlCharSetName] [VARCHAR](100) NULL
) ON [Data]

CREATE TABLE DBREP.TB_VolumesSpaces
(	
	  RegDate DATETIME NOT NULL
	, ComputerName VARCHAR(255) NOT NULL
	, DiskName VARCHAR(255) NOT NULL
	, Size DECIMAL(15,2) NOT NULL
	, FreeSpace DECIMAL(15,2) NOT NULL
) ON [Data]

GO



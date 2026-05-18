CREATE TABLE [CHK].[DiskSpace](
	[ADDomain] [varchar](50) NOT NULL,
	[ServerName] [varchar](100) NOT NULL,
	[MountPoint] [varchar](100) NOT NULL,
	[TotalSizeGB] [decimal](18, 2) NOT NULL,
	[FreeSpaceGB] [decimal](18, 2) NOT NULL,
	[FreePercentage] [decimal](18, 2) NOT NULL,
	[Timestamp] [datetime] NULL
) ON [DBAdmin_Cold_FG_01]
GO

ALTER TABLE [CHK].[DiskSpace] ADD  DEFAULT (getdate()) FOR [Timestamp]
GO

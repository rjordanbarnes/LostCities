IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
  DROP TABLE dbo.Users

IF OBJECT_ID('dbo.Rooms', 'U') IS NOT NULL
  DROP TABLE dbo.Rooms

CREATE TABLE Rooms
(
  RoomId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
  RoomName NVARCHAR(25) NOT NULL,
  Password NVARCHAR(128) NULL,
  CreationDate DATETIME NOT NULL DEFAULT GETDATE(),
  IsActive BIT NOT NULL
);

CREATE TABLE Users
(
  UserId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
  Username NVARCHAR(25) NOT NULL UNIQUE,
  CurrentRoom UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Rooms(RoomID),
  IsHost BIT NOT NULL DEFAULT 0,
  IsReady BIT NOT NULL DEFAULT 0
);

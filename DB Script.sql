
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Products](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProductName] [nvarchar](max) NULL,
	[ProductDescription] [nvarchar](max) NULL,
	[ProductPrice] [int] NULL,
	[ProductStatus] [nvarchar](50) NULL,
	[ProductCreatedDate] [datetime] NULL,
	[ProductUpatedDate] [datetime] NULL,
 CONSTRAINT [PK_ProductDetails] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ApprovalQueue](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProductId] [int] NOT NULL,
	[RequestType] [nvarchar](max) NULL,
	[RequestReason] [nvarchar](max) NULL,
	[RequestDate] [datetime] NULL,
	[RequestStatus] [nvarchar](50) NULL,
	[RequestUpatedDate] [datetime] NULL,
	[RequestIsPosted] [bit] NOT NULL,
	[RequestIsApproved] [char](1) NOT NULL,
 CONSTRAINT [PK_ApprovalQueue] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[ApprovalQueue] ADD  CONSTRAINT [DF_ApprovalQueue_RequestIsPosted]  DEFAULT ((0)) FOR [RequestIsPosted]
GO

ALTER TABLE [dbo].[ApprovalQueue] ADD  CONSTRAINT [DF_ApprovalQueue_RequestIsApproved]  DEFAULT ((0)) FOR [RequestIsApproved]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProductCreated](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProductId] [int] NOT NULL,
	[Name] [varchar](max) NOT NULL,
	[Description] [varchar](max) NOT NULL,
	[Price] [int] NOT NULL,
 CONSTRAINT [PK_ProductCreated] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- EXEC usp_SearchProduct '', 2000,5000,'2023-10-30 17:12:02.160' ,'2023-10-31 17:12:02.160' 
-- =============================================
CREATE PROCEDURE [dbo].[usp_SearchProduct]
	@pName varchar(max)=null,
	@pMinPrice int=0,
	@pMaxPrice int=0,	
	@pMinPostedDate datetime=null,
	@pMaxPostedDate datetime=null
	--
AS
BEGIN

	SET NOCOUNT ON;
	Declare @sqlCmd as nvarchar(max), @SelectClause as nvarchar(max), @whereClause as nvarchar(max) , @OrderByClause as nvarchar(max)

	SET @SelectClause=' Select Id [ProductId], [ProductName],[ProductDescription],[ProductPrice],[ProductStatus],[ProductCreatedDate],[ProductUpatedDate] From [Products] '
	SET @whereClause=' WHERE ProductStatus = ''Active'' '
	SET @OrderByClause=' Order By [ProductCreatedDate] DESC '
	

	IF(@pMinPrice<=0)
	SELECT @pMinPrice= MIN([ProductPrice]) From [Products]

	IF(@pMaxPrice<=0)
	SELECT @pMaxPrice= MAX([ProductPrice]) From [Products]
	
	IF(@pMinPostedDate IS NULL)
	SELECT @pMinPostedDate=  MIN([ProductUpatedDate]) From [Products]

	IF(@pMaxPostedDate IS NULL)
	SELECT @pMaxPostedDate=  MAX([ProductUpatedDate]) From [Products]

		print @pMinPostedDate
	print @pMaxPostedDate

	SET @pMinPostedDate = CAST(@pMinPostedDate AS nvarchar(20))
	SET @pMaxPostedDate =CAST(@pMaxPostedDate AS nvarchar(20))
	
	SET @pMaxPostedDate+=' 23:59:59.998'

	IF(@pName!='')
	SET @whereClause+=' AND ([ProductName] like ''%'+@pName+'%'') '

	SET @whereClause+=' AND ([ProductPrice] >= '+CAST(@pMinPrice AS varchar(20))+' AND [ProductPrice] <='+CAST(@pMaxPrice AS varchar(20))+') '
		
	SET @whereClause+=' AND ([ProductUpatedDate] >= '''+CAST(@pMinPostedDate AS varchar(20))+''' AND [ProductUpatedDate]<='''+CAST(@pMaxPostedDate AS varchar(20))+''')  '


	SET @sqlCmd=@SelectClause+' '+@whereClause+' '+@OrderByClause
	print @pMinPostedDate
	print @pMaxPostedDate
	EXECUTE sp_executesql @sqlCmd
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_SaveProduct]
	@pName varchar(max),
	@pDesc varchar(max),
	@pPrice int,
	@pStatus varchar(50),
	@pRequestType varchar(max),
	@pRequestReason varchar(max),
	@pRequestIsPosted bit,
	@pRequestIsApproved bit
AS
BEGIN

	SET NOCOUNT ON;

	Declare @pID as int
   
	INSERT INTO [Products]([ProductName],[ProductDescription],[ProductPrice],[ProductStatus],[ProductCreatedDate],[ProductUpatedDate]) 
	SELECT @pName,@pDesc,@pPrice,@pStatus,GETDATE(),GETDATE()

	SET @pID=@@IDENTITY

	INSERT INTO [ApprovalQueue]([ProductId],[RequestDate],[RequestStatus],[RequestType], [RequestReason],[RequestIsPosted],[RequestIsApproved])
	SELECT @pID,GETDATE(),'Create',@pRequestType,@pRequestReason,@pRequestIsPosted,@pRequestIsApproved


END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_DeleteProduct]
	@pId int
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE [Products] 
	SET [ProductStatus]			='Pending Approval',
		[ProductUpatedDate]		=GETDATE()
	WHERE [Id]=@pId

	UPDATE [ApprovalQueue]
	SET [RequestStatus]		='Delete',
		[RequestUpatedDate]	=GETDATE(),
		[RequestType]		='Delete Product', 
		[RequestReason]		='Deleting an existing product.',
		[RequestIsPosted]	=0,
		[RequestIsApproved] =0
	WHERE [ProductId]=@pId

END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- usp_UpdateProductStatus 1, false
-- =============================================
CREATE PROCEDURE [dbo].[usp_UpdateProductStatus]
	@pId int,	
	@pIsApproved bit
AS
BEGIN

	SET NOCOUNT ON;
	Declare @RequestedStatus as varchar(50)
	Select  @RequestedStatus = RequestStatus From [ApprovalQueue] Where ProductId=@pId
	
	IF EXISTS( Select 1 From [Products] Where Id=@pId ) 
	BEGIN
		IF (SELECT @pIsApproved)>0
		BEGIN
			IF(@RequestedStatus='Delete')
			BEGIN
				UPDATE [Products] SET [ProductStatus] ='InActive', [ProductUpatedDate] =GETDATE() WHERE [Id]=@pId
				
				UPDATE [ApprovalQueue] SET RequestIsApproved=1, [RequestUpatedDate]=GETDATE(), [RequestReason]=[RequestReason]+' - '+@RequestedStatus+' - Approved' WHERE [ProductId]=@pId	

			END
			ELSE IF(@RequestedStatus='Create')
			BEGIN
				UPDATE [Products] SET [ProductStatus] ='Active', [ProductUpatedDate] =GETDATE() WHERE [Id]=@pId
				
				UPDATE [ApprovalQueue] SET RequestIsApproved=1,RequestIsPosted=1, [RequestUpatedDate]=GETDATE(), [RequestReason]=[RequestReason]+' - '+@RequestedStatus+' - Approved' WHERE [ProductId]=@pId	

			END
			ELSE
			BEGIN
				UPDATE  a SET a.[ProductStatus] ='Active', a.[ProductUpatedDate] =GETDATE(), 
						a.[ProductName]=b.[Name],
						a.[ProductDescription]=b.[Description],
						a.[ProductPrice]=b.[Price]
					FROM [Products] a INNER JOIN [ProductCreated] b On b.[ProductId]=a.[Id]  WHERE a.[Id]=@pId
				
				UPDATE [ApprovalQueue] SET  RequestIsApproved=1, RequestIsPosted=1, [RequestUpatedDate]=GETDATE(), [RequestReason]=[RequestReason]+' - '+@RequestedStatus+' - Approved' WHERE [ProductId]=@pId

			END		

		END
		ELSE
		BEGIN

			IF(@RequestedStatus='Delete')
				BEGIN
					UPDATE [Products] SET [ProductStatus] ='Active', [ProductUpatedDate] =GETDATE() WHERE [Id]=@pId
				
					UPDATE [ApprovalQueue] SET RequestIsApproved=0,RequestIsPosted=1, [RequestUpatedDate]=GETDATE(), [RequestReason]=[RequestReason]+' - '+@RequestedStatus+' - Rejected',[RequestStatus]	='Rejected' WHERE [ProductId]=@pId	

				END
			ELSE IF(@RequestedStatus='Update')
				BEGIN
					UPDATE [Products] SET [ProductStatus] ='Active', [ProductUpatedDate] =GETDATE() WHERE [Id]=@pId

					UPDATE [ApprovalQueue] SET  RequestIsApproved=0, RequestIsPosted=1, [RequestUpatedDate]=GETDATE(), [RequestReason]=[RequestReason]+' - '+@RequestedStatus+' - Rejected',[RequestStatus]	='Rejected' WHERE [ProductId]=@pId
										
				END
			ELSE 
				BEGIN
					UPDATE [Products] SET [ProductStatus] ='InActive', [ProductUpatedDate] =GETDATE() WHERE [Id]=@pId

					UPDATE [ApprovalQueue] SET  RequestIsApproved=0, RequestIsPosted=1, [RequestUpatedDate]=GETDATE(), [RequestReason]=[RequestReason]+' - '+@RequestedStatus+' - Rejected',[RequestStatus]	='Rejected' WHERE [ProductId]=@pId				
						
				END

		END

		DELETE FROM [ProductCreated] WHERE [ProductId]=@pId
	END


END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_UpdateProduct]
	@pId int,
	@pName varchar(max),
	@pDesc varchar(max),
	@pPrice int,
	@pStatus varchar(50),
	@pRequestType varchar(max),
	@pRequestReason varchar(max),
	@pRequestIsPosted bit,
	@pRequestIsApproved bit
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO [ProductCreated] ([ProductId],[Name],[Description],[Price])
	VALUES(@pId,@pName,@pDesc,@pPrice)

	UPDATE [Products] 
	SET [ProductStatus]			=@pStatus,
		[ProductUpatedDate]		=GETDATE()
	WHERE [Id]=@pId

	UPDATE [ApprovalQueue]
	SET [RequestStatus]		='Update',
		[RequestUpatedDate]	=GETDATE(),
		[RequestType]		=@pRequestType, 
		[RequestReason]		=@pRequestReason,
		[RequestIsPosted]	=@pRequestIsPosted,
		[RequestIsApproved]	=@pRequestIsApproved
	WHERE [ProductId]=@pId


END
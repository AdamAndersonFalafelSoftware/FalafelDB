exec dbo.drop_if_exists 'dbo.aspnet_CreateUser'
go
-- Helper procedure to create asp.net membership users in SQL
create procedure dbo.aspnet_CreateUser
	@ApplicationName nvarchar(256),
	@UserName nvarchar(256),
	@Password nvarchar(128),
	@Email nvarchar(256),
	@PasswordQuestion nvarchar(256),
	@PasswordAnswer nvarchar(128),
	@UserId uniqueidentifier out
as
set nocount on 

declare @getutcdate datetime = getutcdate()
declare @salt uniqueidentifier = newid()
declare @encoded_salt nvarchar(128) = dbo.base64_encode(@salt)
declare @encoded_hashed_password nvarchar(128) = dbo.base64_encode(hashbytes('SHA1', convert(varbinary(max), @salt) + convert(varbinary(max), @Password)))
 
exec dbo.aspnet_Membership_CreateUser
	@ApplicationName = @ApplicationName,
	@UserName = @UserName,
	@Password = @encoded_hashed_password,
	@PasswordSalt = @encoded_salt,
	@Email = @Email,
	@PasswordQuestion = @PasswordQuestion,
	@PasswordAnswer = @PasswordAnswer,
	@IsApproved = 1,
	@CurrentTimeUtc = @getutcdate,
	@CreateDate = @getutcdate,
	@UniqueEmail = 0,
	@PasswordFormat = 1,
	@UserId = @UserId out
go
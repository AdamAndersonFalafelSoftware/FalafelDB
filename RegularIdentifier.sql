exec dbo.drop_if_exists 'dbo.RegularIdentifier'
GO
-- Converts an input string to a string that conforms to SQL Server rules for regular identifiers
create function dbo.RegularIdentifier
(
	@identifier varchar(max)
)
returns sysname
as
begin
	select @identifier = stuff(@identifier, n, 1, '_')
	from dbo.sequence
	where n between 1 and len(@identifier)
	and substring(@identifier, n, 1) not like case n when 1 then '[a-zA-Z@#_]' else '[a-zA-Z0-9@#$_]' end
	order by n desc	
	
	return @identifier
end
GO
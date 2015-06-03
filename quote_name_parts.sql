exec dbo.drop_if_exists 'dbo.quote_name_parts'
go
create function dbo.quote_name_parts (
	@name nvarchar(max)
) returns nvarchar(max)
begin
	return
		isnull(quotename(parsename(@name, 4)), '') + '.' +
		isnull(quotename(parsename(@name, 3)), '') + '.' +
		isnull(quotename(parsename(@name, 2)), '') + '.' +
		isnull(quotename(parsename(@name, 1)), '')
end
go
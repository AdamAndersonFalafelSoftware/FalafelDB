exec dbo.drop_if_exists 'dbo.index_id'
go
-- Returns the index_id of the named index if it exists, or null if it doesn't
create function dbo.index_id
(
	@table_name nvarchar(max),
	@index_name sysname
)
returns int
as
begin
	declare @index_id int = null
	
	select @index_id = index_id
	from sys.indexes
	where object_id = object_id(@table_name)
	and name = @index_name
	
	return @index_id
end
go
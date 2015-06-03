exec dbo.drop_if_exists 'dbo.df_create'
go
-- Creates a default on one or more columns with a standard name
create procedure dbo.df_create
	@table_name nvarchar(max),
	@column_pattern nvarchar(max),
	@default_value nvarchar(max)
as
set nocount on

declare @object_id int = object_id(@table_name)

if (@object_id is null)
begin
	raiserror('Table "%s" does not exist', 11, 1, @table_name)
	return
end

declare @stmt nvarchar(max) = 'alter table ' + @table_name + ' add'

select @stmt += '
	constraint ' + quotename('DF_' + parsename(@table_name, 1) + '_' + column_name) + '
		default ' + @default_value + '
		for ' + quotename(column_name)
from information_schema.columns
where table_name = parsename(@table_name, 1)
and column_name like @column_pattern
and table_schema = isnull(parsename(@table_name, 2), table_schema)

exec dbo.sp_executesql @stmt
go
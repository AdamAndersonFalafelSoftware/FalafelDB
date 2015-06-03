exec dbo.drop_if_exists '[dbo].[ix_create]'
GO
-- Creates an index with a standard name
create procedure dbo.ix_create
	@table_name nvarchar(max),
	@column_list nvarchar(max),
	@options varchar(2) = '', -- c: clustered; u: unique
	@column_list_delimiter nvarchar(2) = ','
as
set nocount on

declare @object_id int = object_id(@table_name, 'u')

if (@object_id is null)
begin
	raiserror('Table "%s" does not exist', 11, 1, @table_name)
	return
end

if exists (
	select *
	from dbo.str_split(@column_list, @column_list_delimiter) ss
	left join sys.columns c on c.name = ss.value and c.object_id = @object_id
	where c.object_id is null
)
begin
	raiserror('Column list contains invalid column references', 11, 1)
	return
end

declare @index_name sysname = 'IX_' + parsename(@table_name, 1) + '_' + replace(@column_list, @column_list_delimiter, '_')

if exists (
	select *
	from sys.indexes
	where name = @index_name
	and object_id = object_id(@table_name)
)
begin
	declare @drop_stmt nvarchar(max) = 'drop index ' + quotename(@index_name) + ' on ' + @table_name
	exec dbo.sp_executesql @drop_stmt
end

declare @stmt nvarchar(max) = 'create ' +
	case charindex('u', @options)
		when 0 then ''
		else 'unique '
	end +
	case charindex('c', @options)
		when 0 then ''
		else 'clustered '
	end +
	'index ' + quotename(@index_name) + ' on ' + @table_name +
	'(' +
	stuff(
		(select ',' + quotename(parsename(value, 1))
		from dbo.str_split(@column_list, @column_list_delimiter)
		order by id
		for xml path('')), 1, 1, '') + 
	')'

exec dbo.sp_executesql @stmt
GO
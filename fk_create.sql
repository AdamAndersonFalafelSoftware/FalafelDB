exec dbo.drop_if_exists 'dbo.fk_create'
go
-- Creates a FK with a standard name
create procedure dbo.fk_create
	@fk_table_name nvarchar(max),
	@fk_column_list nvarchar(max),
	@pk_table_name nvarchar(max),
	@pk_column_list nvarchar(max) = null,
	@fk_column_list_delimiter nvarchar(2) = ',',
	@pk_column_list_delimiter nvarchar(2) = null,
	@ix_create bit = 1
as
set nocount on

declare @fk_object_id int = object_id(@fk_table_name, 'u')

if (@fk_object_id is null)
begin
	raiserror('FK Table "%s" does not exist', 11, 1, @fk_table_name)
	return
end

if exists (
	select *
	from dbo.str_split(@fk_column_list, @fk_column_list_delimiter) ss
	left join sys.columns c on c.name = ss.value and c.object_id = @fk_object_id
	where c.object_id is null
)
begin
	raiserror('FK Column list contains invalid column references', 11, 1)
	return
end

declare @pk_object_id int = object_id(@pk_table_name, 'u')

if (@pk_object_id is null)
begin
	raiserror('PK Table "%s" does not exist', 11, 1, @pk_table_name)
	return
end

if exists (
	select *
	from dbo.str_split(isnull(@pk_column_list, @fk_column_list), isnull(@pk_column_list_delimiter, @fk_column_list_delimiter)) ss
	left join sys.columns c on c.name = ss.value and c.object_id = @pk_object_id
	where c.object_id is null
)
begin
	raiserror('PK Column list contains invalid column references', 11, 1)
	return
end

declare @fk_name sysname = quotename('FK_' + parsename(@fk_table_name, 1) + '_' + replace(@fk_column_list, @fk_column_list_delimiter, '_'))

if object_id(parsename(@fk_table_name, 2) + '.' +  @fk_name, 'f') is not null
begin
	declare @drop_stmt nvarchar(max) = 'alter table ' + @fk_table_name + ' drop
		constraint ' + @fk_name
	exec dbo.sp_executesql @drop_stmt
end

declare @stmt nvarchar(max) = 'alter table ' + @fk_table_name + ' add
	constraint ' + @fk_name + '
		foreign key (' +
		stuff(
			(select ',' + quotename(parsename(value, 1))
			from dbo.str_split(@fk_column_list, @fk_column_list_delimiter)
			order by id
			for xml path('')), 1, 1, '') +
		')
		references ' + @pk_table_name + '(' +
		stuff(
			(select ',' + quotename(parsename(value, 1))
			from dbo.str_split(isnull(@pk_column_list, @fk_column_list), isnull(@pk_column_list_delimiter, @fk_column_list_delimiter))
			order by id
			for xml path('')), 1, 1, '') +
		')'

exec dbo.sp_executesql @stmt

if @ix_create = 1
	exec dbo.ix_create
		@table_name = @fk_table_name,
		@column_list = @fk_column_list,
		@options = '',
		@column_list_delimiter = @fk_column_list_delimiter
go
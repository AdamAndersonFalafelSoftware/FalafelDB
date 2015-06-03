if object_id('dbo.drop_if_exists') is not null
	drop procedure dbo.drop_if_exists
GO
-- Drops the named object if it exists
create procedure dbo.drop_if_exists
	@name nvarchar(max)
as
set nocount on

if @name is null
begin
	raiserror('@name is required', 11, 1)
	return
end

declare
	@server sysname = parsename(@name, 4),
	@database sysname = parsename(@name, 3),
	@schema sysname = parsename(@name, 2),
	@object sysname = parsename(@name, 1)
	
if @server is not null
begin
	raiserror('Remote servers are not supported.', 11, 1)
	return
end

declare
	@type char(2),
	@parent_name nvarchar(max),
	@object_id int = object_id(@name)

declare @stmt nvarchar(max) = '
select
	@type = type,
	@parent_name = quotename(object_schema_name(parent_object_id)) + ''.'' + quotename(object_name(parent_object_id))
from ' + isnull(quotename(@database), '') + '.sys.objects
where object_id = @object_id'

exec sp_executesql
	@stmt = @stmt,
	@params = N'
		@type char(2) out,
		@parent_name nvarchar(max) out,
		@object_id int',
	@type = @type out,
	@parent_name = @parent_name out,
	@object_id = @object_id

declare @rowcount int = @@rowcount

if @rowcount = 0
begin
	raiserror('Info: ''%s'' does not exist', 1, 1, @name)
	return
end

declare @type_name varchar(10)

set @type_name = case
	when @type in ('c', 'd', 'f', 'pk', 'uq')
		then 'constraint'
	when @type in ('fn', 'if', 'tf')
		then 'function'
	else case @type
		when 'p'
			then 'procedure'
		when 'tr'
			then 'trigger'
		when 'u'
			then 'table'
		when 'v'
			then 'view'
		else null
	end
end

set @stmt = isnull('use ' + quotename(@database) + '
', '') + case @type_name 
		when 'constraint' then 'alter table ' + @parent_name + ' drop constraint ' + quotename(@object)
		else 'drop ' + @type_name + ' ' + quotename(@schema) + '.' + quotename(@object)
	end
	
exec sp_executesql @stmt
GO
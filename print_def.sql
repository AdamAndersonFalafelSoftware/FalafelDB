exec dbo.drop_if_exists 'dbo.print_def'
GO
-- Outputs the definition of an object 
create procedure [dbo].[print_def]
	@name nvarchar(max)
as
set nocount on

declare
	@object_id int = object_id(@name)
	
if @object_id is null
begin
	raiserror('Object "%s" does not exist', 11, 1, @name)
	return
end
	
declare
	@object_name sysname = object_name(@object_id),
	@object_schema_name sysname = object_schema_name(@object_id),
	@object_definition nvarchar(max)
	
set @name = quotename(@object_schema_name) + '.' + quotename(@object_name)
	
if exists (select * from sys.sql_modules where object_id = @object_id)
	set @object_definition = '
' + object_definition(@object_id)
else
if exists (select * from sys.tables where object_id = @object_id)
begin
	declare @output nvarchar(max), @deferred_ddl nvarchar(max)
	exec dbo.tbl_def @name, @output out, @deferred_ddl out
	set @object_definition = @output + isnull('
GO' + nullif(ltrim(rtrim(@deferred_ddl)), ''), '')
end
	
declare @def nvarchar(max) = 'exec dbo.drop_if_exists ''' + @name + '''
GO' + ltrim(rtrim(@object_definition)) + '
GO'

declare
	@level0type varchar(128),
	@level0name sysname,
	@level1type varchar(128),
	@level1name sysname,
	@level2type varchar(128),
	@level2name sysname

exec dbo.ex_prop_params @name, @level0type out, @level0name out, @level1type out, @level1name out, @level2type out, @level2name out
	
select @def += '
exec sp_addextendedproperty ' + quotename(name, '''') + ', ''' + replace(convert(nvarchar(max), value), '''', '''''') + ''',
	' + quotename(@level0type, '''') + ', ' + quotename(@level0name, '''') + ',
	' + quotename(@level1type, '''') + ', ' + quotename(@level1name, '''') + ',
	null, null'
from fn_listextendedproperty(null, @level0type, @level0name, @level1type, @level1name, null, null)

if @level1type in ('function', 'table', 'view')
	select @def += '
exec sp_addextendedproperty ' + quotename(name, '''') + ', ''' + replace(convert(nvarchar(max), value), '''', '''''') + ''',
	' + quotename(@level0type, '''') + ', ' + quotename(@level0name, '''') + ',
	' + quotename(@level1type, '''') + ', ' + quotename(@level1name, '''') + ',
	''column'', ' + quotename(objname, '''')
	from fn_listextendedproperty(null, @level0type, @level0name, @level1type, @level1name, 'column', null)

if @level1type in ('function', 'table')
	select @def += '
exec sp_addextendedproperty ' + quotename(name, '''') + ', ''' + replace(convert(nvarchar(max), value), '''', '''''') + ''',
	' + quotename(@level0type, '''') + ', ' + quotename(@level0name, '''') + ',
	' + quotename(@level1type, '''') + ', ' + quotename(@level1name, '''') + ',
	''constraint'', ' + quotename(objname, '''')
	from fn_listextendedproperty(null, @level0type, @level0name, @level1type, @level1name, 'constraint', null)

if @level1type in ('table', 'view')
	select @def += '
exec sp_addextendedproperty ' + quotename(name, '''') + ', ''' + replace(convert(nvarchar(max), value), '''', '''''') + ''',
	' + quotename(@level0type, '''') + ', ' + quotename(@level0name, '''') + ',
	' + quotename(@level1type, '''') + ', ' + quotename(@level1name, '''') + ',
	''index'', ' + quotename(objname, '''')
	from fn_listextendedproperty(null, @level0type, @level0name, @level1type, @level1name, 'index', null)

if @level1type in ('function', 'procedure')
	select @def += '
exec sp_addextendedproperty ' + quotename(name, '''') + ', ''' + replace(convert(nvarchar(max), value), '''', '''''') + ''',
	' + quotename(@level0type, '''') + ', ' + quotename(@level0name, '''') + ',
	' + quotename(@level1type, '''') + ', ' + quotename(@level1name, '''') + ',
	''parameter'', ' + quotename(objname, '''')
	from fn_listextendedproperty(null, @level0type, @level0name, @level1type, @level1name, 'parameter', null)

if @level1type in ('table', 'view')
	select @def += '
exec sp_addextendedproperty ' + quotename(name, '''') + ', ''' + replace(convert(nvarchar(max), value), '''', '''''') + ''',
	' + quotename(@level0type, '''') + ', ' + quotename(@level0name, '''') + ',
	' + quotename(@level1type, '''') + ', ' + quotename(@level1name, '''') + ',
	''trigger'', ' + quotename(objname, '''')
	from fn_listextendedproperty(null, @level0type, @level0name, @level1type, @level1name, 'trigger', null)

exec dbo.print_long @def
GO
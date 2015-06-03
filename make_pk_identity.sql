exec dbo.drop_if_exists 'dbo.make_pk_identity'
go
create procedure dbo.make_pk_identity
	@name sysname
as
set nocount on

declare @object_id int = object_id(@name)

if @object_id is null
begin
	raiserror('Object "%s" does not exist', 11, 1, @name)
	return
end

declare @object_name sysname = object_name(@object_id)
declare @schema_name sysname = object_schema_name(@object_id)
declare @col_name sysname

select @col_name = col_name(ic.object_id, ic.column_id)
from sys.indexes i
join sys.index_columns ic on ic.object_id = i.object_id and ic.index_id = i.index_id
where i.object_id = @object_id
and i.is_primary_key = 1

if @@rowcount = 0
begin
	raiserror('No PK defined', 11, 1)
	return
end

if @@rowcount > 1
begin
	raiserror('PK has more than one column', 11, 1)
	return
end

declare @drop_fks nvarchar(max) = ''

select
	@drop_fks += '
alter table ' + quotename(object_schema_name(parent_object_id)) + '.' + quotename(object_name(parent_object_id)) + ' drop
	' + quotename(object_name(object_id))
from sys.foreign_keys fk
where fk.referenced_object_id = @object_id

declare @cols nvarchar(max) = stuff((select ',' + quotename(name) from sys.columns where object_id = @object_id for xml path('')), 1, 1, '')
declare @output nvarchar(max), @deferred_ddl nvarchar(max)
exec dbo.tbl_def @name, @output out, @deferred_ddl out, @options = 'make_pk_identity;defer_pk'

declare @temp_name sysname = newid()

declare @stmt nvarchar(max) = '
begin tran
set xact_abort on

' + @drop_fks + '

exec sp_rename ''' + @name + ''', ''' + @temp_name + '''

' + @output + '

set identity_insert ' + quotename(@schema_name) + '.' + quotename(@object_name) + ' on

insert ' + quotename(@schema_name) + '.' + quotename(@object_name) + '(' + @cols + ')
select ' + @cols + '
from ' + quotename(@schema_name) + '.' + quotename(@temp_name) + '

set identity_insert ' + quotename(@schema_name) + '.' + quotename(@object_name) + ' off

drop table ' + quotename(@schema_name) + '.' + quotename(@temp_name) + '

' + @deferred_ddl + '

commit'

exec sp_executesql @stmt
go
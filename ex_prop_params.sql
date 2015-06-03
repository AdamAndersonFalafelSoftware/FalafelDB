exec dbo.drop_if_exists 'dbo.ex_prop_params'
go
-- Takes a fully qualified object name and returns parameters suitable for passing to sp_[add|drop]extendedproperty or fn_listextendedproperty
create procedure dbo.ex_prop_params
	@object_fullname nvarchar(max),
	@level0type varchar(128) out,
	@level0name sysname out,
	@level1type varchar(128) out,
	@level1name sysname out,
	@level2type varchar(128) out,
	@level2name sysname out
as
set nocount on

select top 1
	@level0name = parsename(@object_fullname, n),
	@level1name = parsename(@object_fullname, n - 1),
	@level2name = parsename(@object_fullname, n - 2)
from dbo.sequence
where n between 1 and 3
and parsename(@object_fullname, n) is not null
order by n desc

declare @schema_id int = schema_id(@level0name)

if @schema_id is null or @level1name is null
begin
	raiserror('Only schema-scoped objects are supported right now. If you need to describe a database-level object, modify this procedure', 11, 1)
	return
end

set @level0type = 'schema'

select @level1type = dbo.object_type_name(type)
from sys.objects
where schema_id = @schema_id
and name = @level1name

if @level1type is null
begin
	raiserror('Object not found. (%s)', 11, 1, @object_fullname)
	return
end

-- Automatically detect level1 type & name for level2 items specified at level1
if @level1type in ('trigger', 'constraint')
begin
	set @level2type = @level1type
	set @level2name = @level1name
	
	select
		@level1type = dbo.object_type_name(parent.type),
		@level1name = parent.name
	from sys.objects parent
	join sys.objects child on child.parent_object_id = parent.object_id
	where child.schema_id = @schema_id
	and child.name = @level2name
end

declare @level1object_id int = object_id(quotename(@level0name) + '.' + quotename(@level1name))

if @level2name is not null and @level2type is null
begin
	if exists (
		select *
		from sys.indexes
		where object_id = @level1object_id
		and name = @level2name
	) set @level2type = 'INDEX' else
	if exists (
		select *
		from sys.parameters
		where object_id = @level1object_id
		and name = @level2name
	) set @level2type = 'PARAMETER' else
	if exists (
		select *
		from sys.columns
		where object_id = @level1object_id
		and name = @level2name
	) set @level2type = 'COLUMN' else
		select @level2type = dbo.object_type_name(type)
		from sys.objects
		where parent_object_id = @level1object_id
		and name = @level2name

	if @level2type is null
	begin
		raiserror('Object not found. (%s)', 11, 1, @object_fullname)
		return
	end
end
go
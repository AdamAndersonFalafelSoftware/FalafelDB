exec dbo.drop_if_exists 'dbo.script_data'
go
create procedure dbo.script_data
	@source_name nvarchar(257)
as
set nocount on

declare
	@source_id int = object_id(@source_name)

if @source_id is null
begin
	raiserror('@source_name "%s" not found', 11, 1, @source_name)
	return
end

set @source_name = quotename(object_schema_name(@source_id)) + '.' + quotename(object_name(@source_id))

declare @has_identity bit = case when exists (select * from sys.columns where object_id = @source_id and is_identity = 1) then 1 else 0 end

declare @result nvarchar(max) = case @has_identity when 1 then 'set identity_insert ' + @source_name + ' on

' else '' end + 'merge ' + @source_name + ' target
using ('

declare @stmt nvarchar(max)

select @stmt = isnull(@stmt + ' + '', '' +', '
select @values = isnull(@values + ''
union all
'', '''') + ''select '' + ') + '
	' + case
			when type_name(c.system_type_id) in ('char', 'text', 'varchar') then 'isnull('''''''' + replace(' + quotename(c.name) + ', '''''''', '''''''''''') + '''''''', ''null'')'
			when type_name(c.system_type_id) in ('nchar', 'ntext', 'nvarchar') then 'isnull(''N'''''' + replace(' + quotename(c.name) + ', '''''''', '''''''''''') + '''''''', ''null'')'
			when type_name(c.system_type_id) in ('binary', 'varbinary', 'smalldatetime', 'datetime', 'date', 'time', 'datetime2', 'datetimeoffset', 'uniqueidentifier') then 'isnull('''''''' + convert(varchar(max), ' + quotename(c.name) + ') + '''''''', ''null'')'
			when type_name(c.system_type_id) in ('bit', 'tinyint', 'smallint', 'int', 'bigint', 'decimal', 'numeric', 'float', 'real', 'smallmoney', 'money') then 'isnull(convert(varchar(max), ' + quotename(c.name) + '), ''null'')'
			else '''unsupported type "' + type_name(c.system_type_id) + '"'''
		end
from sys.columns c
where c.object_id = @source_id
order by c.column_id

set @stmt += '
from ' + @source_name + ''

declare @values nvarchar(max)

exec sp_executesql @stmt, N'@values nvarchar(max) out', @values = @values out

set @result += replace('
' + @values, '
', '
	') + '
) source (' + stuff((select ',' + quotename(name) from sys.columns where object_id = @source_id order by column_id for xml path('')), 1, 1, '') + ') on'

declare @index_id int

select top 1 @index_id = index_id
from sys.indexes
where object_id = @source_id
and is_primary_key = 1

select top 1 @index_id = index_id
from sys.indexes
where object_id = @source_id
and is_unique_constraint = 1
and @index_id is null

declare @join nvarchar(max)

select @join = isnull(@join + '
	and ', '
	') + 'source.' + quotename(col_name(object_id, column_id)) + ' = target.' + quotename(col_name(object_id, column_id))
from sys.index_columns
where object_id = @source_id
and index_id = @index_id
order by index_column_id

set @result += isnull(@join, '
	-- CANNOT AUTO-DETECT JOIN CONDITION')

-- when matched
set @result += '
when matched then update set'

select @result = @result + case row_number() over (order by c.column_id) when 1 then '' else ',' end + '
	' + quotename(col_name(c.object_id, c.column_id)) + ' = source.' + quotename(col_name(c.object_id, c.column_id))
from sys.columns c
left join sys.index_columns ic on ic.object_id = c.object_id and ic.column_id = c.column_id and ic.index_id = @index_id
where c.object_id = @source_id
and ic.object_id is null
order by c.column_id

-- when not matched
set @result += '
when not matched then
	insert (' + stuff((select ',' + quotename(name) from sys.columns where object_id = @source_id order by column_id for xml path('')), 1, 1, '') + ')
	values (' + stuff((select ',source.' + quotename(name) from sys.columns where object_id = @source_id order by column_id for xml path('')), 1, 1, '') + ')'

-- when not matched by source
set @result += '
when not matched by source then delete;' + case @has_identity when 1 then '

set identity_insert ' + @source_name + ' off' else '' end

exec dbo.print_long @result
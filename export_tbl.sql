exec dbo.drop_if_exists '[dbo].[export_tbl]'
GO
create procedure dbo.export_tbl
	@tbl_name sysname,
	@quote nvarchar(max) = '"',
	@escape nvarchar(max) = '""'
as
set nocount on

declare @stmt nvarchar(max) = 'select '''

select @stmt += case row_number() over (order by c.column_id) when 1 then '' else ',' end + dbo.quote_data(c.name, @quote, @escape)
from sys.columns c
where c.object_id = object_id(@tbl_name)
order by c.column_id

set @stmt += ''' as Data
union all
select'

select @stmt += case row_number() over (order by c.column_id) when 1 then '' else ' + '','' + ' end + '
	' + 'dbo.quote_data(isnull(cast(' + quotename(c.name) + ' as nvarchar(max)), ''''),''' + @quote + ''',''' + @escape + ''')'
	from sys.columns c
	where c.object_id = object_id(@tbl_name)
	order by c.column_id
	
set @stmt += '
from ' + @tbl_name

set nocount off

print @stmt
exec sp_executesql @stmt
GO
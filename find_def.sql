exec dbo.drop_if_exists 'dbo.find_def'
GO
-- Returns the names of objects whose definition contains @def
create procedure [dbo].[find_def]
	@def varchar(max)
as
set nocount on

select distinct schema_name(o.schema_id) as [schema_name], o.name as [object_name]
from sys.sql_modules sm
join sys.objects o on o.object_id = sm.object_id
where sm.definition like '%' + @def + '%'
order by o.name

return @@error
GO
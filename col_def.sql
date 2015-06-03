exec dbo.drop_if_exists 'dbo.col_def'
GO
-- Outputs column metadata in valid SQL for creating tables
create view dbo.col_def
as
select
	table_catalog,
	table_schema,
	table_name,
	column_name,
	ordinal_position,
	data_type +
		case
			when data_type in ('binary', 'char', 'float', 'nchar', 'nvarchar', 'varbinary', 'varchar') then
				'(' +
					case character_maximum_length
						when -1 then
							'max'
						else cast(character_maximum_length as varchar(5))
					end +
				')'
			when data_type in ('decimal', 'numeric') then
				'(' + cast(numeric_precision as varchar(3)) + ',' + cast(numeric_scale as varchar(3)) + ')'
			else ''
		end as data_type,
	case is_nullable
		when 'NO' then 'not null'
		when 'YES' then 'null'
		else null
	end as is_nullable,
	column_default
from information_schema.columns
GO
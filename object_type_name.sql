exec dbo.drop_if_exists 'dbo.object_type_name'
go
-- Converts type codes from sys.objects into their corresponding SQL keywords
create function dbo.object_type_name
(
	@type char(2)
)
returns varchar(10)
as
begin
	return case
		when @type in ('AF', 'FN', 'FS', 'FT', 'IF', 'TF') then 'function'
		when @type in ('C', 'D', 'F', 'PK', 'UQ') then 'constraint'
		when @type in ('IT', 'S', 'U') then 'table'
		when @type in ('P', 'PC', 'RF', 'X') then 'procedure'
		when @type in ('PG') then 'plan'
		when @type in ('R') then 'rule'
		when @type in ('SN') then 'synonym'
		when @type in ('SQ') then 'queue'
		when @type in ('TA', 'TR') then 'trigger'
		when @type in ('TT') then 'type'
		when @type in ('V') then 'view'
		else null
	end
end
go
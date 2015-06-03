exec dbo.drop_if_exists 'dbo.str_split'
GO
-- Splits a string on a specified delimiter into a table
create function dbo.str_split
(
	@str varchar(max),
	@delim varchar(max)
)
returns table
as
return
select
	row_number() over (order by n) as id,
	substring
	(
		@str,
		n + len(@delim) - 1,
		case charindex(@delim, @str, n)
			when 0 then len(@str)
			else charindex(@delim, @str, n) - n - len(@delim) + 1
		end
	) as value
from dbo.sequence
where n between 1 and len(@str)
and
(
	n = 1
	or substring(@str, n - 1, len(@delim)) = @delim
)
GO
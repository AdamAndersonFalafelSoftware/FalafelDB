exec dbo.drop_if_exists 'dbo.keep_chars'
GO
-- Strings characters not matching @pattern from @source
create function dbo.keep_chars
(
	@source varchar(max),
	@pattern varchar(max)
)
returns sysname
as
begin
	select @source = stuff(@source, n, 1, '')
	from dbo.sequence
	where n between 1 and len(@source)
	and substring(@source, n, 1) not like @pattern
	order by n desc	
	
	return @source
end
GO
exec dbo.drop_if_exists 'dbo.trim_left'
go
create function dbo.trim_left (
	@value nvarchar(max),
	@chars nvarchar(max)
) returns nvarchar(max)
begin
	declare @n int

	select top 1 @n = n
	from dbo.sequence
	where n > 0
	and charindex(substring(@value, n, 1), @chars) = 0
	order by n

	return stuff(@value, 1, @n - 1, '')
end
go
exec dbo.drop_if_exists 'dbo.print_long'
GO
-- Prints strings over 8000 bytes long
create procedure dbo.print_long
	@long_str nvarchar(max)
as
set nocount on

declare
	@cr char(1),
	@lf char(1),
	@long_str_len int,
	@pos int,
	@len int,
	@is_crlf bit,
	@max_len int
	
set @cr = char(13)
set @lf = char(10)
set @max_len = 4000 -- 8000 if @long_str is varchar(max)

set @long_str_len = len(@long_str)
set @pos = 1

while ((@long_str_len - @pos) > @max_len)
begin
	select top 1
		@len = n,
		@is_crlf = case substring(@long_str, @pos + n - 1, 2) when @cr + @lf then 1 else 0 end
	from dbo.sequence
	where n between 1 and @max_len
	and substring(@long_str, @pos + n, 1) in (@cr, @lf)
	and substring(@long_str, @pos + n, 2) <> @cr + @lf
	order by n desc
	
	print substring(@long_str, @pos, @len - @is_crlf)
	
	set @pos = @pos + @len + 1
end

print substring(@long_str, @pos, @max_len)
GO
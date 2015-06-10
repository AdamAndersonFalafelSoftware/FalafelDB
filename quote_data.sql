exec dbo.drop_if_exists '[dbo].[quote_data]'
GO
create function dbo.quote_data(@data nvarchar(max), @quote nvarchar(max), @escape nvarchar(max))
returns nvarchar(max)
as
begin
	return @quote + replace(@data, @quote, @escape) + @quote
end
GO
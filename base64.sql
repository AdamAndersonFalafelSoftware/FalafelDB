exec dbo.drop_if_exists 'dbo.base64_encode'
go
create function dbo.base64_encode
(
	@source varbinary(max)
)
returns varchar(max)
as
begin
	return cast('' as xml).value('xs:base64Binary(sql:variable("@source"))', 'varchar(max)')
end
go
exec dbo.drop_if_exists 'dbo.base64_decode'
go
create function dbo.base64_decode
(
	@source varchar(max)
)
returns varbinary(max)
as
begin
	return cast('' as xml).value('xs:base64Binary(sql:variable("@source"))', 'varbinary(max)')
end
go
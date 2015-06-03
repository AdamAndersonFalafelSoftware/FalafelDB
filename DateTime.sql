exec dbo.drop_if_exists 'dbo.DateTime'
GO
-- Creates a datetime value from discrete numeric values
create function dbo.DateTime
(
	@yyyy smallint,
	@mm tinyint,
	@dd tinyint,
	@hh tinyint,
	@nn tinyint,
	@ss tinyint,
	@ms smallint
)
returns datetime
as
begin
	return
		replace(str(@yyyy, 4) + '-' + str(@mm, 2) + '-' + str(@dd, 2), ' ', '0') +
		'T' +
		replace(str(@hh, 2) + ':' + str(@nn, 2) + ':' + str(@ss, 2) + '.' + str(@ms, 3), ' ', '0')
end
GO
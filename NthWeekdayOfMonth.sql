exec dbo.drop_if_exists 'dbo.NthWeekdayOfMonth'
GO
-- Returns the date of the Nth weekday of a month
create function dbo.NthWeekdayOfMonth
(
	@n tinyint,
	@dw tinyint,
	@mm tinyint,
	@yyyy smallint
)
returns datetime
as
begin
	declare @1stOfMonth datetime, @1stDW tinyint, @dd tinyint
	set @1stOfMonth = dbo.DateTime(@yyyy, @mm, 1, 0, 0, 0, 0)
	set @1stDW = datepart(dw, @1stOfMonth)	
	set @dd = ((7 - @1stDW + @dw) % 7) + 1 + (7 * (@n - 1))
	return dbo.DateTime(@yyyy, @mm, @dd, 0, 0, 0, 0)
end
GO
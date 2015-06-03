-- Creates a sequence table that is not compatible with Azure, but does not leave unused space in the index
if object_id('dbo.sequence') is null
begin
	create table dbo.sequence
	(
		n smallint not null
	)
end
GO
if (select count(*) from dbo.sequence) < 65536
begin
	truncate table dbo.sequence;

	with
	n1 (n)
	as
	(
		select 0
		union all
		select 0
	),
	n2 (n)
	as
	(
		select 0
		from n1 a, n1 b
	),
	n4 (n)
	as
	(
		select 0
		from n2 a, n2 b
	),
	n8 (n)
	as
	(
		select 0
		from n4 a, n4 b
	),
	n16 (n)
	as
	(
		select 0
		from n8 a, n8 b
	)
	insert dbo.sequence (n)
	select (row_number() over (order by n)) - 1 - 32768
	from n16
end
GO
if object_id('dbo.PK_sequence') is null
begin
	alter table dbo.sequence add
		constraint PK_sequence
			primary key clustered (n)
			with fillfactor = 100
end
GO
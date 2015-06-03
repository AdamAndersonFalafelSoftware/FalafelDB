exec dbo.drop_if_exists 'dbo.describe_object'
go
/*
Adds or updates a description to an object.
Specify object with two or three part names.
First part must be schema.
Second part must be a schema-scoped object. Supported types:
	Functions
	Procedures
	Tables
	Views
Optional third part must be a child object of the schema-scoped object. Supported types:
	Indexes
	Parameters
	Columns
	Constraints
	Triggers
*/
create procedure dbo.describe_object
	@object_fullname nvarchar(max),
	@description nvarchar(3750)
as
set nocount on

declare
	@level0type varchar(128),
	@level0name sysname,
	@level1type varchar(128),
	@level1name sysname,
	@level2type varchar(128),
	@level2name sysname

exec dbo.ex_prop_params @object_fullname, @level0type out, @level0name out, @level1type out, @level1name out, @level2type out, @level2name out

if exists (
	select *
	from fn_listextendedproperty(
		'MS_Description',
		@level0type, @level0name,
		@level1type, @level1name,
		@level2type, @level2name)
) exec sp_updateextendedproperty
	'MS_Description', @description,
	@level0type, @level0name,
	@level1type, @level1name,
	@level2type, @level2name
else exec sp_addextendedproperty
	'MS_Description', @description,
	@level0type, @level0name,
	@level1type, @level1name,
	@level2type, @level2name
go
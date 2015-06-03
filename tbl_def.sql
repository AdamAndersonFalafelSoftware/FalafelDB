exec dbo.drop_if_exists '[dbo].[tbl_def]'
GO
-- Constructs SQL that defines the source table, optionally renaming to the target name
create procedure dbo.tbl_def
	@source_name nvarchar(max), -- schema and object name allowed
	@output nvarchar(max) out,
	@deferred_ddl nvarchar(max) out,
	@target_name nvarchar(max) = null,
	@options varchar(max) = null -- drop_if_exists|make_pk_identity|defer_fks|defer_pk
as
declare @object_name sysname = parsename(@source_name, 1)
declare @schema_name sysname = isnull(parsename(@source_name, 2), 'dbo')
declare @new_object_name sysname = parsename(isnull(@target_name, @source_name), 1)
declare @new_schema_name sysname = isnull(parsename(isnull(@target_name, @source_name), 2), 'dbo')
declare @new_tbl_name nvarchar(257) = quotename(isnull(@new_schema_name, @schema_name)) + '.' + quotename(isnull(@new_object_name, @object_name))
set @output = isnull(@output, '')
set @deferred_ddl = isnull(@deferred_ddl, '')

if patindex('%drop_if_exists%', @options) > 0
begin
	set @output += '
exec dbo.drop_if_exists ''' + @new_tbl_name + '''
go'
end

-- Table columns
set @output += '
create table ' + @new_tbl_name + '
('
select
	@output += case c.column_id when 1 then '' else ',' end + '
	' + quotename(c.name) + ' ' + quotename(t.name) + case
	when t.name in ('binary', 'char', 'float', 'varbinary', 'varchar') then
		'(' + case c.max_length when -1 then 'max' else cast(c.max_length as varchar(5)) end + ')'
	when t.name in ('nchar', 'nvarchar') then
		'(' + case c.max_length when -1 then 'max' else cast(c.max_length / 2 as varchar(5)) end + ')'
	when t.name in ('decimal', 'numeric') then
		'(' + cast(c.precision as varchar(3)) + ',' + cast(c.scale as varchar(3)) + ')'
	else ''
end
+ case c.is_nullable when 1 then ' null' else ' not null' end
-- Identity property cannot be combined with defaults
+ case
	when c.is_identity = 1 then ' identity'
	when pk_col.object_id is not null and c.column_id = pk_col.column_id_min and c.column_id = pk_col.column_id_max and patindex('%make_pk_identity%', @options) > 0 then ' identity'
	else isnull('
		constraint ' + quotename('DF_' + @new_object_name + '_' + col_name(parent_object_id, parent_column_id)) + '
			default ' + definition, '') end,
	@deferred_ddl += isnull('
exec dbo.sp_bindrule ''' + quotename(object_schema_name(c.rule_object_id)) + '.' + quotename(object_name(c.rule_object_id)) + ''', ''' + quotename(@new_schema_name) + '.' + quotename(@new_object_name) + '.' + quotename(c.name) + '''', '')
from sys.columns c
join sys.types t on t.user_type_id = c.user_type_id
left join sys.default_constraints df on df.parent_object_id = c.object_id
	and df.parent_column_id = c.column_id
left join (
	select i.object_id, min(ic.column_id) as column_id_min, max(ic.column_id) as column_id_max
	from sys.indexes i
	join sys.index_columns ic on ic.object_id = i.object_id
		and ic.index_id = i.index_id
	where i.is_primary_key = 1
	group by i.object_id, i.index_id
) pk_col on pk_col.object_id = c.object_id
where c.object_id = object_id(@source_name)
order by c.column_id

-- Primary key
declare @pk nvarchar(max)
select @pk = '
	constraint ' + quotename('PK_' + @new_object_name) + '
		primary key ' + case index_id when 1 then 'clustered' else 'nonclustered' end + ' (' + stuff((
			select ',' + quotename(col_name(object_id, column_id))
			from sys.index_columns
			where object_id = i.object_id
			and index_id = i.index_id
			order by key_ordinal
			for xml path('')), 1, 1, '') + ')'
from sys.indexes i
where object_id = object_id(@source_name)
and is_primary_key = 1
and index_id > 0

if patindex('%defer_pk%', @options) > 0
	set @deferred_ddl += 'alter table ' + quotename(@new_schema_name) + '.' + quotename(@new_object_name) + ' add' + @pk
else
	set @output += ',' + @pk

-- TODO: Check constraints (none in development DB)

-- Foreign keys
declare @fks nvarchar(max)
;with fk_cols as (
	select
		constraint_object_id as object_id,
		constraint_column_id as fk_col_id,
		col_name(parent_object_id, parent_column_id) as parent_column,
		col_name(referenced_object_id, referenced_column_id) as referenced_column
	from sys.foreign_key_columns
)
select @fks = isnull(@fks + ',
	', '') + 'constraint ' + quotename('FK_' + @new_object_name + (select '_' + parent_column from fk_cols where object_id = fk.object_id order by fk_col_id for xml path(''))) + '
		foreign key (' + stuff((select ',' + quotename(parent_column) from fk_cols where object_id = fk.object_id order by fk_col_id for xml path('')), 1, 1, '') + ')
		references ' + quotename(object_schema_name(fk.referenced_object_id)) + '.' + quotename(object_name(fk.referenced_object_id)) + '(' + stuff((select ',' + quotename(referenced_column) from fk_cols where object_id = fk.object_id order by fk_col_id for xml path('')), 1, 1, '') + ')'
from sys.foreign_keys fk
where fk.parent_object_id = object_id(@source_name)

if patindex('%defer_fks%', @options) > 0
	set @deferred_ddl += isnull('
alter table ' + quotename(@new_schema_name) + '.' + quotename(@new_object_name) + ' add
	' + @fks, '')
else
	set @output += isnull(',
	' + @fks, '')

-- Foreign key references
declare @fk_refs nvarchar(max)
;with fk_cols as (
	select
		constraint_object_id as object_id,
		constraint_column_id as fk_col_id,
		col_name(parent_object_id, parent_column_id) as parent_column,
		col_name(referenced_object_id, referenced_column_id) as referenced_column
	from sys.foreign_key_columns
)
select @fk_refs = isnull(@fk_refs, '') + '
alter table ' + quotename(object_schema_name(fk.parent_object_id)) + '.' + quotename(object_name(fk.parent_object_id)) + ' add
	constraint ' + quotename('FK_' + object_name(fk.parent_object_id) + (select '_' + parent_column from fk_cols where object_id = fk.object_id order by fk_col_id for xml path(''))) + '
		foreign key (' + stuff((select ',' + quotename(parent_column) from fk_cols where object_id = fk.object_id order by fk_col_id for xml path('')), 1, 1, '') + ')
		references ' + @new_tbl_name + '(' + stuff((select ',' + quotename(referenced_column) from fk_cols where object_id = fk.object_id order by fk_col_id for xml path('')), 1, 1, '') + ')'
from sys.foreign_keys fk
where fk.referenced_object_id = object_id(@source_name)

set @deferred_ddl += isnull(@fk_refs, '')

-- Indexes
;with ix_cols as (
	select
		object_id,
		index_id,
		key_ordinal,
		col_name(object_id, column_id) as col_name,
		case is_descending_key when 1 then ' desc' else '' end as direction,
		is_included_column
		from sys.index_columns
)
select @deferred_ddl += isnull('
create '
+ case is_unique when 1 then 'unique ' else '' end
+ case index_id when 1 then 'clustered ' else '' end
+ 'index ' + quotename('IX_' + @new_object_name + (select '_' + col_name from ix_cols where object_id = i.object_id and index_id = i.index_id and is_included_column = 0 order by key_ordinal for xml path('')))
+ ' on ' + quotename(@new_schema_name) + '.' + quotename(@new_object_name)
+ '(' + stuff((select ',' + quotename(col_name) + direction from ix_cols where object_id = i.object_id and index_id = i.index_id and is_included_column = 0 order by key_ordinal for xml path('')), 1, 1, '') + ')'
+ isnull('include (' + stuff((select ',' + col_name from ix_cols where object_id = i.object_id and index_id = i.index_id and is_included_column = 1 order by key_ordinal for xml path('')), 1, 1, '') + ')', '')
+ ' on ' + quotename(fg.name), '')
from sys.indexes i
join sys.filegroups fg on fg.data_space_id = i.data_space_id
where i.object_id = object_id(@source_name)
and i.is_primary_key = 0

select @output += '
) on ' + quotename(fg.name)
from sys.indexes i
join sys.filegroups fg on fg.data_space_id = i.data_space_id
where i.object_id = object_id(@source_name)
and i.index_id < 2
GO
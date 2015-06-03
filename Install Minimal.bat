rem Installs base supporting objects for printing definitions, finding definitions, and splitting strings
setlocal enabledelayedexpansion
set SQLCMDSERVER=server_name
set SQLCMDDBNAME=db_name
set SQLCMDUSER=user_name
set SQLCMDPASSWORD=password

sqlcmd -i sequence.sql,drop_if_exists.sql,print_long.sql,object_type_name.sql,ex_prop_params.sql,tbl_def.sql,print_def.sql,find_def.sql,str_split.sql
rem Installs all scripting helpers plus other sometimes useful functions
setlocal enabledelayedexpansion
set SQLCMDSERVER=server_name
set SQLCMDDBNAME=db_name
set SQLCMDUSER=user_name
set SQLCMDPASSWORD=password

sqlcmd -i sequence.sql,drop_if_exists.sql,print_long.sql,object_type_name.sql,ex_prop_params.sql,tbl_def.sql,print_def.sql,find_def.sql,str_split.sql,col_def.sql,describe_object.sql,df_create.sql,fk_create.sql,index_id.sql,ix_create.sql,keep_chars.sql,make_pk_identity.sql,DateTime.sql,NthWeekdayOfMonth.sql,RegularIdentifier.sql,base64.sql,aspnet_CreateUser.sql
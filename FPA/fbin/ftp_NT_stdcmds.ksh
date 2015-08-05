####  
####  FTP COMMANDS AND RESPONSES
####  This file contains the standard commands and responses for connecting to a Microsoft Windows based FTP server.
####  
####  Each FTP command must be listed here as ftpC_<cmd>="command_string"
####  And Successful return code must be listed as ftpS_<cmd>="==<success_string>=="
####  And Error return codes must be listed as ftpE_<cmd>="==<err_string1>==<err_string2>==" 
####  NOTE: The error string is expected at the beginning of the response line. 
####  NOTE: Each error string and success string is surrounded by two 
####  equal-signs, allowing multiple success and error conditions.  
####  The ftpC_* command will be executed in the ftp session. 
####  The first return string which matches will be used to determine success 
####  or error of the command. 
####  

export ftpC_shell="!"
export ftpE_shell="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_shell="==200=="   # 200 whatever shell command is issued, it must end by echoing a line beginning with "200 " in order to be treated as a successful command.  

export ftpC_site="site"
export ftpE_site="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_site="==200=="   # 200 SITE command was accepted

export ftpC_passive="passive"
export ftpE_passive="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_passive="==Passive=="

export ftpC_stat="stat"
export ftpE_stat="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_stat="==Connected=="

export ftpC_ftp="ftp"
export ftpE_ftp="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_ftp="==Connected==220=="

export ftpC_user="user "
export ftpE_user="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_user="==230=="

export ftpC_cd="cd "
export ftpE_cd="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_cd="==250=="

export ftpC_pwd="pwd "
export ftpE_pwd="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_pwd="==257=="

export ftpC_prompt="prompt "
export ftpE_prompt="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_prompt="==Interactive==200=="

export ftpC_binary="binary "
export ftpE_binary="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_binary="==200=="

export ftpC_ascii="ascii "
export ftpE_ascii="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_ascii="==200=="

export ftpC_dir="dir "
export ftpE_dir="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_dir="==226==250=="
export ftpC_dir_date_fmt="dir "

export ftpC_put="put "
export ftpE_put="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_put="==226==250=="

export ftpC_get="get "
export ftpE_get="==Not==?Invalid==202==221==421==425==426==451==452==500==501==502==503==504==505==506==530==550==551==553==554=="
export ftpS_get="==226==250=="

export ftpC_bye="bye "
export ftpE_bye=""
export ftpS_bye="==221==COMPLETED_FTP_CONNECTION:=="

export ftpC_End_Send="End_Send"
export ftpE_End_Send="==Not"
export ftpS_End_Send="==COMPLETED_FTP_CONNECTION:==Date:=="

ftp_generic_errors="==Not==?Invalid==221==226==421==425==426==451==452==500==501==502==503==504==505==506==522==530==550==551==553==554=="
ftp_generic_warnings="==202=="


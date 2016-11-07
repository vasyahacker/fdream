#!/bin/sh

CFG_FILE='config.rb'
DB_FILE='db/sity.db'
SQL_FILE='db/dump.sql'

platform='unknown'
unamestr=`uname`
MD5="md5"
md5opts=''
[ "$unamestr" == "Linux" ] && { MD5="md5sum"; md5opts='--' platform='linux'; }
[ "$unamestr" == 'Darwin' ] && { platform='darwin'; }
[ "$unamestr" == 'FreeBSD' ] && { platform='freebsd'; }

CRE='\033[0;31m'
CGR='\033[0;32m'
CBGR='\033[1;32m'
CYE='\033[0;33m'
CUPUR='\033[4;35m'
CICYA='\033[0;96m'
CBIWH='\033[1;97m'
CIBL='\033[0;94m'
NC='\033[0m'

# read_char var
read_char() {
  stty -icanon -echo
  eval "$1=\$(dd bs=1 count=1 2>/dev/null)"
  stty icanon echo
}

Yn(){
	printf "$2 [${CBIWH}Y${NC}/n]: "
  local  __resultvar=$1
	while IFS= read_char char
	do
    [ "$char" == "n" ] || [ "$char" == "N" ] && { printf "${CBIWH}n${NC}\n"; myresulto='n'; break; }
    [ "$char" == $'\0' ] || [ "$char" == "y" ] || [ "$char" = "Y" ] && { printf "${CBIWH}y${NC}\n"; myresulto='y' ; break; }
	done
  local  myresult=`echo "$myresulto"`
  eval $__resultvar="'$myresult'"
}

yN(){
	printf "$2 [y/${CBIWH}N${NC}]: "
  local  __resultvar=$1
	while IFS= read_char char
	do
    [ "$char" == $'\0' ] || [ "$char" == "n" ] || [ "$char" == "N" ] && { printf "${CBIWH}n${NC}\n"; myresulto='n'; break; }
    [ "$char" == "y" ] || [ "$char" = "Y" ] && { printf "${CBIWH}y${NC}\n"; myresulto='y' ; break; }
	done
  local  myresult=`echo "$myresulto"`
  eval $__resultvar="'$myresult'"
}

read_email(){
  local  __resultvar=$1
	while read -p "$2: " addr
	do
		case $addr in
			*@?*.?*) break ;;
			*) echo "некорректный адрес" ;;
		esac
	done
  local  myresult=`echo "$addr"`
  eval $__resultvar="'$myresult'"
}

read_num() {
  local  __resultvar=$1
	while read -p "$2: " mynum
	do
		case $mynum in
    	''|*[!0-9]*) echo "Введите число" ;;
			*) break ;;
		esac
	done	
  local  myresult=`echo "$mynum"`
  eval $__resultvar="'$myresult'"
}

DEPS=""
for r in "sqlite3" "$MD5" 
do
	type $r >/dev/null 2>&1 || {  DEPS="$DEPS $r"; }
done

[ -n "$DEPS" ] && {
	printf >&2 "${CYE}Установите пожалуйста$DEPS, это необходимо для работы скрипта.${NC}\n"
	exit 1
}

clear

i=17 ; while [ "$i" -lt 59 ]; do printf "\033[38;05;${i}m*";i=$((i+1)); done
printf "${NC}\n* Конфигуратор MUD сервера \"${CICYA}Заб${CYE}ытый${CGR} сон${NC}\" *\n"
i=58 ; while [ "$(( i > 16 ))" -ne 0 ]; do printf "\033[38;05;${i}m*";i=$((i-1)); done
printf ${NC}

echo

del="already"

if [ -f $CFG_FILE ]
then
  echo "Файл конфигурации уже существует"
	
	yN del "Cоздать новый?"
	[ $del == 'y' ] && { mv $CFG_FILE old_$CFG_FILE; }
fi

echo
main_jid=''
jab='n'
[ $del == 'already' ] || [ $del == 'y' ] && {
	q1="Запускать MUD через jabber?"
	q2="JID бота"
	q3="Пароль для авторизации бота на jabber сервере"
	q4="JID для отправки отладочной информации"		

	Yn jab "$q1"
	[ $jab == 'y' ] && {
    echo "\n# $q1\n@jabber_enable = true" >> $CFG_FILE
    echo
		read_email jid $q2
		echo "\n# $q2\n@bot_jid = '$jid'" >> $CFG_FILE
		echo
		read -p "$q3: " pass
		echo "\n# $q3\n@bot_jpass = '$pass'" >> $CFG_FILE
		echo
		read_email main_jid $q4
		echo "\n# $q4\n\$MAINADDR = '$main_jid'" >> $CFG_FILE

	} || {
		echo "\n# $q1\n@jabber_enable = false\n# $q2\n@bot_jid = ''\n# $q3\n@bot_jpass = ''\n# $q4\n\$MAINADDR = ''" >> $CFG_FILE
	}
	echo
	q="Логин для SMTP авторизации на серверах gmail (вместе с @)"
	read_email login "$q"
	echo "\n# $q\n\$SMTP_LOGIN = '$login'" >> $CFG_FILE
	echo
	q="Пароль для SMTP авторизации на gmail"
	read -p "$q: " pass
  echo "\n# $q\n\$SMTP_PWD = '$pass'" >> $CFG_FILE
	echo 
	q="Номер локации для возврата"
	read_num retloc "$q (1 для первоначальной инициализации)"
  echo "\n# $q\n@return_location = $retloc" >> $CFG_FILE

	q="Номер стартовой локации"
	read_num sloc "$q (1 для первоначальной инициализации)"
  echo "\n# $q\n@start_location = $sloc" >> $CFG_FILE
  echo
	echo "Настройки сохранены в $CFG_FILE"
}
echo
Yn db "Cоздать базу данных?"
[ $db == 'y' ] && { 
	
	[ ! -f $SQL_FILE ] && { echo "Файл дампа $SQL_FILE отсутствует! Создать бд неполучится."; exit 1; }

	if [ -f $DB_FILE ]
	then
	  echo "Файл базы данных уже существует"
		yN del "Очистить?"
		[ $del == 'y' ] && { rm -f $DB_FILE; } || { echo "Конфигурация завершена"; exit 0; }
	fi

	sqlite3 $DB_FILE < $SQL_FILE
	echo
	echo "Файл бд успешно создан"
	echo
	Yn adduser "Добавить JID администратора?"
	[ $adduser == 'y' ] && {

		use_main='n'
		[ $jab == 'y' ] && {
			Yn use_main "Использовать $main_jid в качестве jid администратора?"
		}

		[ $use_main == 'n' ] && { read_email main_jid "Введите JID администратора"; }
	
		read -p "Введите пароль администратора для telnet: " pass 
		md5pass=`printf "$pass" | $MD5 $md5opts | cut -d ' ' -f 1`
		
		echo "INSERT INTO 'chars' VALUES(1,'$main_jid','admin','admin','admin','admin','admin','male',1,'admin','false','','','admin','','',0,1478441247,1478440768,'','$md5pass');" | sqlite3 $DB_FILE
	}
}
echo
echo "Конфигурация завершена"

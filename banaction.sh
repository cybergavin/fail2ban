#!/bin/bash
# Author           : cybergavin
# Date             : 28-FEB-2020
# Description      : This script is executed when Fail2Ban takes action to ban an IP. The script
#                    logs the time, IP being banned and the reason for banning and such data will
#                    facilitate decisions on permanent blacklisting of IPs.
#
######################################################################################################
#
# Variables
#
sender_name="cybergavin"
sender_email="mail@cybergav.in"
rec_email=""   # Multiple email adddresses may be used and separated with commas
valid_user_bantime=`fail2ban-client get sshd-valid bantime`
#
# Determine Script Location
#
if [ -n "`dirname $0 | grep '^/'`" ]; then
   SCRIPT_LOCATION=`dirname $0`
elif [ -n "`dirname $0 | grep '^..'`" ]; then
     cd `dirname $0`
     SCRIPT_LOCATION=$PWD
     cd - > /dev/null
else
     SCRIPT_LOCATION=`echo ${PWD}/\`dirname $0\` | sed 's#\/\.$##g'`
fi
#
# Log stderr and stdout
#
exec 1> ${SCRIPT_LOCATION}/banaction.stdout
exec 2> ${SCRIPT_LOCATION}/banaction.stderr
#
# Parse input
#
unset myip myuser
if [ $# -eq 0 ]; then
   printf "ERROR : Invalid script usage.\nUSAGE: /etc/fail2ban/banaction.sh -i <ip> -u <user> -f <failures>"
   exit 1
else
   while getopts ":i:u:f:" opt; do
    case $opt in
        i )  myip=${OPTARG}
             ;;
        u )  myuser=${OPTARG}
             ;;
        f )  myfails=${OPTARG}
             ;;
        : )  printf "\n$0: Missing argument for -$OPTARG option\n"
             exit 2
             ;;
        \? ) printf "ERROR : Invalid script usage.\nUSAGE: /etc/fail2ban/banaction.sh -i <ip> -u <user> -f <failures>"
             exit 1
             ;;
    esac
  done
shift $(($OPTIND - 1))
fi
#
# Send email alert if the user is valid
#
if [ -n "`id -un $myuser`" ]; then
cat <<EOF | /usr/sbin/sendmail -f $sender_email $rec_email
Subject: $sender_name : Blocked SSH connectivity from $myip
Date: `LC_TIME=C date -u +"%%a, %%d %%h %%Y %%T +0000"`
From: $sender_name <$sender_email>
To: $rec_email
Content-Type: text/html
<html>
<head>
<style>
.datagrid1 table { border: 1px solid black; border-collapse: collapse; text-align: justify; width: 40%; font: normal 12px/150% Verdana, Arial, Helvetica, sans-serif; }
.datagrid1 td {border: 1px solid black;}
</style>
</head>
<body>
The XXXYYY Application has been protected by Fail2Ban as per the following:<br /><br />
<div class="datagrid1">
<table>
        <tr>
                <td width="20%" style="background-color:#BDBDBD;"><b>Hostname</b></td>
                <td width="20%">$HOSTNAME</td>
        </tr>
        <tr>
                <td width="20%" style="background-color:#BDBDBD;"><b>Banned IP</b></td>
                <td width="20%">$myip</td>
        </tr>
        <tr>
                <td width="20%" style="background-color:#BDBDBD;"><b>User</b></td>
                <td width="20%">$myuser</td>
        </tr>
        <tr>
                <td width="20%" style="background-color:#BDBDBD;"><b>#Failures</b></td>
                <td width="20%">$myfails</td>
        </tr>
        <tr>
                <td width="20%" style="background-color:#BDBDBD;"><b>Ban Duration</b></td>
                <td width="20%">$(( valid_user_bantime/60 )) minutes</td>
        </tr>
</table>
</div>
<br /><br />
<b>NOTE:</b>To unban the above IP address, login on <b>$HOSTNAME</b> as <b>esuser</b> and execute the following command: <br /><br />
<font size="2" face="Courier New" >sudo fail2ban-client set sshd-valid unbanip $myip</font>
</body>
</html>
EOF
fi
#
# Log Fail2Ban data
#
if [ ! -d ${SCRIPT_LOCATION}/data ]; then
   mkdir ${SCRIPT_LOCATION}/data
fi
DATAFILE=${SCRIPT_LOCATION}/data/banaction_`date '+%b%Y'`.csv
TDATE=`date '+%Y-%m-%d'`
TTIME=`date '+%H:%M:%S'`
if [ ! -f $DATAFILE ]; then
   echo "DATE,TIME,BANNED IP,USER" > $DATAFILE
   echo "${TDATE},${TTIME},${myip},${myuser}" >> $DATAFILE
else
   echo "${TDATE},${TTIME},${myip},${myuser}" >> $DATAFILE
fi
#
# Housekeep
#
if [ -d ${SCRIPT_LOCATION}/data ]; then
   find ${SCRIPT_LOCATION}/data -type f -name "banaction*.csv" -mtime +180 | xargs rm -f
fi
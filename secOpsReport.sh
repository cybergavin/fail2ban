#!/bin/bash
# Created By       : cybergavin
# Created On       : 17-MAR-2020
# Description      : This script sends an email with the TOP 5 most frequently banned IPs to the IT Security Operations
#                    team for further analysis and action (e.g. submit a request to Infrastructure Services for the
#                    permanent ban of "bad" IPs on the frontend firewalls.
#
######################################################################################################
#
# Variables
#
sender_name="cybergavin"
sender_email="mail@cybergav.in"
rec_email=""  # Multiple email adddresses may be used and separated with commas
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
SCRIPT_NAME=`basename $0`
#
# Log stderr and stdout
#
exec 1> ${SCRIPT_LOCATION}/${SCRIPT_NAME%%.*}.stdout
exec 2> ${SCRIPT_LOCATION}/${SCRIPT_NAME%%.*}.stderr
#
# Generate report and send email
#
if [ ! -d ${SCRIPT_LOCATION}/data ]; then
   mkdir ${SCRIPT_LOCATION}/data
fi
my_report=${SCRIPT_LOCATION}/data/${SCRIPT_NAME%%.*}_`date '+%b%Y'`.txt
my_report_html=${my_report%%.*}.html
cat <<EOF > $my_report_html
<html>
<head>
<style>
.datagrid1 table { border: 1px solid black; border-collapse: collapse; text-align: justify; width: 30%; font: normal 12px/150% Verdana, Arial, Helvetica, sans-serif; }
.datagrid1 td,th {border: 1px solid black;}
</style>
</head>
<body>
        Security Operations <br /><br />
        Here are the <b>TOP 5 MOST FREQUENTLY BANNED IPs</b> in $(date '+%B %Y' --date="last month") on $HOSTNAME :<br /><br />
<div class="datagrid1">
<table>
<tr>
        <th width="20%">IP ADDRESS</th>
        <th width="10%">#BANS</th>
</tr>
EOF
awk -F, '$3 != "BANNED IP" {print $3}' ${SCRIPT_LOCATION}/data/banaction*.csv | sort | uniq -c | sort -rk 1 | head -5 | sed 's/^ *//g;s/ /,/g' > $my_report
for f2b in `cat $my_report`
do
my_ip=`echo $f2b | cut -d, -f2`
my_bc=`echo $f2b | cut -d, -f1`
cat <<EOF >> $my_report_html
<tr>
        <td width="20%">$my_ip</td>
        <td width="10%" align="center">$my_bc</td>
</tr>
EOF
done
cat <<EOF >> $my_report_html
</table>
</div>
<br /><br />
<p align="justify">Based on your analysis of the above IP addresses, you may opt to request the Network Admins to implement a permanent ban of one or more of the above IP addresses on the PAN firewalls.</p>
</body>
</html>
EOF
cat <<EOF | /usr/sbin/sendmail -f $sender_email $rec_email
Subject: $sender_name : $(date '+%B %Y' --date="last month") BANNED IP Report
Date: `LC_TIME=C date -u +"%%a, %%d %%h %%Y %%T +0000"`
From: $sender_name <$sender_email>
To: $rec_email
Content-Type: text/html

`cat $my_report_html`

EOF
#
# Housekeep
#
if [ -d ${SCRIPT_LOCATION}/data ]; then
   find ${SCRIPT_LOCATION}/data -type f -name "${SCRIPT_NAME%%.*}*.txt" -mtime +180 | xargs rm -f
fi
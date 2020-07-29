#!/bin/sh
# usage: ./ddns.sh ddns.conf
# by 68xg.com or 百度搜索：广州Linux
if [ "$#" != 1 ];then
	echo "param error."
	exit 0
fi
ACCOUNT=""
PASSWORD=""
DOMAIN=""
SUBDOMAIN=""
RECORD_LINE=""

DOMAIN_ID=""  
current_ip=""
dnspod_load_config(){
	cfg=$1;
	content=`cat ${cfg}`;
	ACCOUNT=`echo "${content}" |grep 'ACCOUNT'| sed 's/^ACCOUNT=[\"]\(.*\)[\"]/\1/'`;
	PASSWORD=`echo "${content}" |grep 'PASSWORD'| sed 's/^PASSWORD=[\"]\(.*\)[\"]/\1/'`;
	DOMAIN=`echo "${content}" |grep 'DOMAIN='| sed 's/^DOMAIN=[\"]\(.*\)[\"]/\1/'`;
	RECORD_LINE=`echo "${content}" |grep 'RECORD_LINE'| sed 's/^RECORD_LINE=[\"]\(.*\)[\"]/\1/'`;
    SUBDOMAIN=${DOMAIN%%.*}
    DOMAIN=${DOMAIN#*.}
} 
#域名是否需要更新
dnspod_is_record_updated(){
    options="login_token=${ACCOUNT},${PASSWORD}&format=json";
    out=$(curl -s -k https://dnsapi.cn/Record.List -d "${options}&domain=${DOMAIN}&sub_domain=${SUBDOMAIN}")
    #echo $out
    #resolve_ip=$(echo $out | sed 's/.*"value":"\([0-9.]*\)",.*/\1/g')
    resolve_ip=${out#*value\":\"};
    resolve_ip=${resolve_ip%%\"*}
    #current_ip=$(curl -s icanhazip.com)
    current_ip=$(curl -s members.3322.org/dyndns/getip)
    echo $resolve_ip
    echo $current_ip 
    if [ "$resolve_ip" = "$current_ip" ]; then
        echo "Record updated."
        exit 0;
    fi
}
#获得域名的id
dnspod_domain_get_id(){
	options="login_token=${ACCOUNT},${PASSWORD}";
	out=$(curl -s -k https://dnsapi.cn/Domain.List -d ${options});
    for line in $out;do
        if [ $(echo $line|grep '<id>' |wc -l) != 0 ];then
            DOMAIN_ID=${line%<*};
            DOMAIN_ID=${DOMAIN_ID#*>};
            #echo "domain id: $DOMAIN_ID";
        fi
        if [ $(echo $line|grep '<name>' |wc -l) != 0 ];then
            DOMAIN_NAME=${line%<*};
            DOMAIN_NAME=${DOMAIN_NAME#*>};
            #echo "domain name: $DOMAIN_NAME";
            if [ "$DOMAIN_NAME" = "$DOMAIN" ];then
               break;
            fi
        fi
    done
	out=$(curl -s -k https://dnsapi.cn/Record.List -d "${options}&domain_id=${DOMAIN_ID}")
    for line in $out;do
        if [ $(echo $line|grep '<id>' |wc -l) != 0 ];then
            RECORD_ID=${line%<*};
            RECORD_ID=${RECORD_ID#*>};
            #echo "record id: $RECORD_ID";
        fi
        if [ $(echo $line|grep '<name>' |wc -l) != 0 ];then
            RECORD_NAME=${line%<*};
            RECORD_NAME=${RECORD_NAME#*>};
            #echo "record name: $RECORD_NAME";
            if [ "$RECORD_NAME" = "$SUBDOMAIN" ];then
               break;
            fi
        fi
    done
    echo "$RECORD_NAME:$RECORD_ID"
}

dnspod_update_record_ip(){
	#curl -k https://dnsapi.cn/Record.Ddns -d "login_token=${ACCOUNT},${PASSWORD}&domain_id=${DOMAIN_ID}&record_id=${RECORD_ID}&sub_domain=${RECORD_NAME}&record_line=${RECORD_LINE}"
    curl -X POST https://dnsapi.cn/Record.Modify -d "login_token=${ACCOUNT},${PASSWORD}&format=json&domain_id=${DOMAIN_ID}&record_id=${RECORD_ID}&sub_domain=${RECORD_NAME}&value=${current_ip}&record_type=A&record_line=${RECORD_LINE}"
}

main(){
	dnspod_load_config $1
	dnspod_is_record_updated
	dnspod_domain_get_id
	dnspod_update_record_ip
}

main $1

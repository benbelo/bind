#!/bin/bash

# Ce script copie le serial du bas a la place de celui du haut
# Il verifie que le serial du bas n est pas identique a l heure actuelle
# et sed le serial du bas avec le timestamp actuel (YYYYMMDDHH)

date +%Y%m%d%H > date.txt

file=db.esiee
bottomserial=$(cat $file | grep Serial | awk '{print $1}')
topserial=$(cat $file | grep last | awk '{print $6}')
timestamp=$(cat date.txt)
refreshbind="/usr/local/sbin/bind-refresh.sh"
restartbind="systemctl restart bind9"
temp=$bottomserialplusone

if [[ $bottomserial = $timestamp ]] && [[ $topserial = $bottomserial ]]; then
    echo "Serials are the same, adding 1 to the bottom serial"
    bottomserialplusone=$(awk "BEGIN {print $bottomserial + 1}")
        sed -i "10s/$bottomserial/$bottomserialplusone/g" "$file"

else

    cp $file backup/.

    echo "Copying actual serial into old one"
          sed -i "s/$topserial/$bottomserial/g" "$file"

    echo "Updating new serial"
          sed -i "10s/$bottomserial/$timestamp/" "$file"

    echo "Serials were udpated for $file"

fi

echo "Restarting Bind9 in ns1"
    $restartbind && sleep 2 && systemctl status bind9 |grep ago

if [[ $(dig @localhost esiee.fr. |grep ANSWER: |awk '{print $10}' | cut -f1 -d ",") = "1" ]]; then

echo "Restarting Bind9 in ns3"
    ssh ns3 "$refreshbind && sleep 2 && systemctl status bind9 |grep ago"

echo "Restarting Bind9 in system-po"
    ssh 10.64.160.13 "$refreshbind && sleep 2 && systemctl status bind9 |grep ago"

echo "Script terminated, if errors please look out"

fi
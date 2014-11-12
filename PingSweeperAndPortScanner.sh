#!/bin/bash
#Author: BinaryWeaver
#This script will sweep the IP range of the selected adapter for IP's in its range. You can also specify an IP range to scan.
#The script will offer an oppurtunity to peform a TCP connect ports scan on common ports, for all hosts in your subnet
#To configure which ports to scan create a common-tcp-ports.txt file in the same directory as the script and specify the tcp ports with a space between each port i.e: 80 443 22 3389

#Enumarate adapters on local machine
adapters=$(ifconfig | grep "Link" | cut -d" " -f1 | grep -v '^$')

echo "============================="
echo "Please type the name of an adapter or nothing to specify an IP range"
echo "============================="
echo $adapters
read selectedAdapter
echo $selectedAdapter

#Specify an IP range to scan 
if [$selectedAdapter == ""]; then
	echo "Please enter IP range in notation 10.0.0.1 10.0.0.254"
	read ipRange
#	echo $ipRange
	hostMin=$(echo $ipRange | cut -d" " -f1)
	hostMax=$(echo $ipRange | cut -d" " -f2)	
else

	ip=$(ifconfig $selectedAdapter | grep 'inet addr:' | cut -d":" -f2 | cut -d" " -f1)
	echo "IP address:      "$ip
	subnet=$(ifconfig wlan0 | grep 'Mask:' | cut -d":" -f4)
	echo "Subnet    :      "$subnet
	hostMin=$(ipcalc $ip"/"$subnet | grep "HostMin" | cut -d" " -f4)
	echo "Starting Host:   "$hostMin
	hostMax=$(ipcalc $ip"/"$subnet | grep "HostMax" | cut -d" " -f4)
	echo "Ending Host:    "$hostMax
	hostCount=$(ipcalc $ip"/"$subnet | grep "Hosts" | cut -d" " -f2)
	echo "#Hosts:	      "$hostCount
fi
echo "==========================="
echo "Press any key to continue or ctrl+c to exit"
read
clear
clear

echo "The following hosts are repsonding to pings:"


minOctet4=$(echo $hostMin | cut -d"." -f1)
maxOctet4=$(echo $hostMax | cut -d"." -f1)
minOctet3=$(echo $hostMin | cut -d"." -f2)
maxOctet3=$(echo $hostMax | cut -d"." -f2)
minOctet2=$(echo $hostMin | cut -d"." -f3)
maxOctet2=$(echo $hostMax | cut -d"." -f3)
minOctet1=$(echo $hostMin | cut -d"." -f4)
maxOctet1=$(echo $hostMax | cut -d"." -f4)

#Create temporary IP to store IP address in range
echo '' > targets.txt

for oc4Counter in $(seq $minOctet4 $maxOctet4); do
	for oc3Counter in $(seq $minOctet3 $maxOctet3); do
		for oc2Counter in $(seq $minOctet2 $maxOctet2); do
			for oc1Counter in $(seq $minOctet1 $maxOctet1); do
				currentIp=$oc4Counter"."$oc3Counter"."$oc2Counter"."$oc1Counter 
				echo $currentIp >> targets.txt
				ping -c1 $currentIp | grep "bytes from" | cut -d" " -f4 | cut -d":" -f1 &
			done

		done

	done

done

echo "Perform TCP scan of all hosts in subnet(n to cancel)?"
read performTcpScan

if [ "$performTcpScan" == y ] ;
then
	echo '' > scanresults.txt
	#Perform TCP ports scan on common ports
	ports=$(cat common-tcp-ports.txt)
	for host in $(cat targets.txt); do
		nc -zv $host $ports 2>&1 | grep 'succeed' &
	done
fi

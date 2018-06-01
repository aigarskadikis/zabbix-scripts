#!/bin/sh

# output.txt - file with all processing matching the pattern
# pid_list.txt - same as output.txt, but only with pid list
# 

path="/var/log/zabbix"
FLAG=0
if [ -f $path/output.txt ]
then
rm $path/output.txt
fi

if [ -f $path/pid_list.txt ]
then
rm $path/pid_list.txt
fi

#current time
ctime=`date +%s`

#[p]rocess list. [w]ide output. specify user defined f[o]rmat
/bin/ps -A -www -o lstart,pid,user,args | /usr/bin/grep [z]abbix_agent > $path/output.txt

#list [e]very process on the system. do [f]ull format listing
/bin/ps -ef > $path/out.txt

#extract only the pid list
cat $path/output.txt|  awk '{print $6}' > $path/pid_list.txt

#empty the file 'a.txt'
/bin/cat /dev/null > $path/a.txt
#create an array 'list' for the further loop
list=`cat $path/pid_list.txt`

#start loop with pidlist
for pid in $(cat $path/pid_list.txt)
do

#take one pid and compare it to the pids in the process file which match the pattern defined in the start
#awk uses pid number as [F]ield seperator and print the first column which in this case is column [lstart]
time_field=`grep $pid $path/output.txt | awk -F "$pid" '{print $1}'`
#i hope that pid number will be never the current year, otherwise this can jenerate misleading result.

#put human readable time in file
echo $time_field >> $path/za.txt

#convert human readable time to unixtime
stime=`date -d "$time_field" "+%s"`

#write the unixtime in file too
echo $stime >> $path/za.txt

#calculate how much time has elapsed
time_elapse=`expr $ctime - $stime`

#put the process duration stamp in the file
echo $time_elapse >> $path/za.txt

#compare if this duration is not very long
if [ $time_elapse -gt 10 ]; then
#if the process is long then put in on the file
echo $pid >> $path/a.txt
#fire up flag
FLAG=1
fi

done

#if flag is fired
if [ $FLAG == 1 ]; then
	#print on screen
	echo "detected"
	#and empty the file
	/bin/cat /dev/null > $path/long.processes.txt
		#take every long running process
		for id in `cat $path/a.txt`
		do
		#put [e]verything in file 
		ps -ef | grep -i $id >> $path/long.processes.txt
		done
else
echo "no processes"
fi

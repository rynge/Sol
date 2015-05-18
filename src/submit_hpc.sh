#!/bin/bash
# Script for submitting workers to the UA HPC through PBS
# Code modified from Group 1's sol_rad_hack.sh

# Define default values for variables

### Change address to your U of A email address for email notifications
ADDRESS="nrcallahan@email.arizona.edu"

### Change to your HPC group name to automatically charge the appopriate group
GROUP="jdpellet"

# These variables are modified by passed arguments
PRIORITY="windfall"
NODES=1
EMAIL="#"
WALLTIME=1
PROJECT="-M trad_eemt"
PASSWORD=""

# Read and process the arguments
while getopts ":eg:n:p:a:sw:P:" o ; do
	case "${o}" in 
		# s = standard priority
		s)
			PRIORITY="standard"
			;;

		# n = Number of nodes (individual processor/memory combos)
		n)
			NODES=${OPTARG}

			# Check for an integer
			if [ $NODES -eq $NODES ] 2> /dev/null; then 

				# Check upper bounds
				if [ $NODES -gt 200 ] ; then
					NODES=150
					echo "You can request up to 200 nodes. Defaulting to 150."
				fi

				# Check lower bounds
				if [ $NODES -lt 1 ] ; then
					NODES=1
					echo "You must request at least 1 node. Defaulting to 1."
				fi

			# Not an integer option
			else
				echo "The -n argument requires an integer option. Aborting."
				exit 1
			fi
			;;

		# e = disable auto email when job starts and ends
		e) 
			EMAIL="### "
			;;

		# g = HPC group to charge for time
		g)
			GROUP=${OPTARG}	
			;;

		# w = Wall Time (Computation time per processor)
		w)
			WALLTIME=${OPTARG}

			# Check that it is an integer
			if [ $WALLTIME -eq $WALLTIME ] 2> /dev/null ; then 
				# Check upper bounds
				if [ $WALLTIME -gt 240 ] ; then 
					echo "Limited to a maximum of 240 hours of wall time. Defaulting to 240."
					WALLTIME=240
				fi

				# Check Lower Bounds
				if [ $WALLTIME -lt 1 ] ; then
					echo "Walltime must be at least 1 hour to use this script. Defaulting to 1."
					WALLTIME=1
				fi
			fi
			;;

		# p = Makeflow/WorkQueue Project Name
		p)
			PROJECT="-M ${OPTARG}"
			;;

		# a = Master address/port combination
		a)
			PROJECT=${OPTARG}
			;;

		# P - password file
		P)
			PASSWORD="--password ${OPTARG}"
			;;

		# Default Case = Unknown option
		*) 
			echo "Usage: submit_worker executable_name [-e] [-g group_name] [-n #] "
			echo $'\t[-p project_name] [-s] [-w #]'
			echo
			echo "Creates a script to submit workers to the UA HPC system with an idle timeout of 5 minutes instead of the default 15 minutes."
			echo
			echo $'\t-e\tDisables the email notifications when the job begins and ends (Enabled by default).'
			echo $'\t-g\tSpecify the group to charge for resource utilization.'
			echo $'\t-n\tSets the number of workers to request. Defaults to 1.'
			echo $'\t-p\tSpecify the project name to connect the worker to. Defaults to trad_eemt'
			echo $'\t-a\tSpecify the IP and port of the master. Enclose them in double quotes. Cannot be used with -p.'
			echo $'\t-s\tSets the priority to standard. Default is windfall.'
			echo $'\t-w\tSpecify the walltime for the calculations in hours. Defaults to 1 hour.'
			echo $'\t-P\tSpecify the password file to use for authentication between workers and the master.'

			exit 1
	esac			
done	# End argument reading

echo $'\t --- Submission Values ---'
echo 

# Let User Verify Output
echo "Group Name           : ${GROUP}"

if [ ${EMAIL} = "###" ] ; then
	echo "Email                : Notifications Disabled"
else
echo "Email                : ${ADDRESS}"
fi

echo
echo "Workers Requested    : ${NODES}"
echo "Time Requested       : ${WALLTIME} hours"
echo "Priority Requested   : ${PRIORITY}"

echo
if [ -z "${PASSWORD}" ] ; then 
	echo "Password File        : None Specified"
else
	echo "Password File        : ${PASSWORD:11}"
fi

if [[ "${PROJECT}" == -M* ]] ; then
	echo "Project Name         : ${PROJECT:3}"
else
	echo "Connecting to Master : ${PROJECT}"
fi 
echo
read -p "Hit [Ctrl]-[C] to abort, or any key to start processing...."
echo

wait

# Finish calculating variables
CPUTIME=$(($WALLTIME * $NODES))
WALLTIME=$WALLTIME:0:0

SCRIPT="qsub_wq_worker_${USER}.pbs"

### Start of PBS Code
cat > "${SCRIPT}" << __EOF__
#!/bin/csh

#PBS -N wq_worker_${TIMESTAMP}
${EMAIL}PBS -m bea
#PBS -M $ADDRESS

#PBS -W group_list=$GROUP
#PBS -l jobtype=serial
#PBS -q $PRIORITY
#PBS -l select=1:ncpus=1:mem=2gb
#PBS -l pvmem=2gb
#PBS -l place=pack:shared
#PBS -l walltime=$WALLTIME
#PBS -l cput=$WALLTIME

### Code to Execute
cd $PWD

source /usr/share/Modules/init/csh
module load unsupported
module load czo/sol/0.0.1
source /unsupported/czo/czorc_csh

date
echo "work_queue_worker ${PASSWORD} ${PROJECT}"
work_queue_worker $PASSWORD $PROJECT -t 180 -p $PORT -d all
date
__EOF__


### End of PBS Code

# Change the script to an executable and submit it with qsub
chmod 755 $SCRIPT
INDEX=0

while [ $INDEX -lt $NODES ] ; do 
	qsub $SCRIPT
	INDEX=$(( $INDEX + 1))
done

rm $SCRIPT

# Check the status of the submission
qstat -u $USER

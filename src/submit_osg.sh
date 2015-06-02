#!/bin/bash

set -e

# Script for submitting workers to the Open Science Grid

# Define default values for variables

### Change to your OSG project name to automatically charge the appopriate project
ACCTPROJECT="OSG-Staff"

# These variables are modified by passed arguments
JOBCOUNT=1
PROJECT="-M trad_eemt_osgtest"
PASSWORD=""

# Read and process the arguments
while getopts ":n:p:a:P:" o ; do
	case "${o}" in 

		# n = Number of jobs
		n)
			JOBCOUNT=${OPTARG}

			# Check for an integer
			if [ $JOBCOUNT -eq $JOBCOUNT ] 2> /dev/null; then 

				# Check lower bounds
				if [ $JOBCOUNT -lt 1 ] ; then
					JOBCOUNT=1
					echo "You must request at least 1 job. Defaulting to 1."
				fi

			# Not an integer option
			else
				echo "The -n argument requires an integer option. Aborting."
				exit 1
			fi
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
			echo $'\t-n\tSets the number of nodes to request. Defaults to 1.'
			echo $'\t-p\tSpecify the project name to connect the worker to. Defaults to trad_eemt'
			echo $'\t-a\tSpecify the IP and port of the master. Enclose them in double quotes. Cannot be used with -p.'
			echo $'\t-P\tSpecify the password file to use for authentication between workers and the master.'

			exit 1
	esac			
done	# End argument reading

echo $'\t --- Submission Values ---'
echo 

# Let User Verify Output
echo "Accounting project   : ${ACCTPROJECT}"

echo
echo "Jobs Requested       : ${JOBCOUNT}"

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

# keep logs on the scratch filesystem
WORK_DIR=/local-scratch/$USER/workqueue-workers/`/bin/date +'%F_%H%M%S'`
mkdir -p $WORK_DIR/logs
cd $WORK_DIR

# we need a wrapper to load modules
cat >wrapper.sh <<EOF
#!/bin/bash
set -x
set -e
module load python/2.7
module load grass
module load cctools
work_queue_worker -d all $PASSWORD $PROJECT -s \$PWD -t 300
EOF
chmod 755 wrapper.sh

# htcondor_submit file
cat >htcondor.sub <<EOF
universe = vanilla

executable = wrapper.sh

requirements = CVMFS_oasis_opensciencegrid_org_REVISION >= 3954 && OSGVO_OS_STRING == "RHEL 6"

output = logs/\$(Cluster).\$(Process).out
error = logs/\$(Cluster).\$(Process).err
log = logs/\$(Cluster).\$(Process).log

ShouldTransferFiles = YES
when_to_transfer_output = ON_EXIT

+projectname = "$ACCTPROJECT" 

notification = Never

queue $JOBCOUNT
EOF

condor_submit htcondor.sub


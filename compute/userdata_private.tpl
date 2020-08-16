#!/bin/bash
echo "Host: ${host_name}" >> /var/log/log.txt
echo "Starting update ..." >> /var/log/log.txt
yum -y update
yum -y install python3
pip3 install boto3 
pip3 install jq
echo "... update finished." >> /var/log/log.txt

echo "Starting cw log script creation ..." >> /var/log/log.txt

# create script directory
scriptdir=/var/myscripts
scriptfile=send_cw_event.sh
mkdir -p $scriptdir

# shell command to send CloudWatch events (for triggering mylambda who has subscribed to the log group)
# space needed after ! to prevent bash history substitution (shebang may contain space before command)
# ${message} is replaced by terraform, $EC2_AZ is ignored by TF but replaced by bash at runtime
# terraform gives an error if there are unknown variables in curly brackets!
echo "
#! /bin/bash

# Script for an ec2 with Amazon AMI to send Cloudwatch events with a time stamp and a message

# Get AZ and region where this ec2 is running
EC2_AZ=\`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone\`
export EC2_AZ
echo EC2_AZ: \$EC2_AZ
EC2_REGION=\"\`echo \\\"\$EC2_AZ\\\" | sed 's/[a-z]$//'\`\"
export AWS_DEFAULT_REGION=\$EC2_REGION
echo AWS_DEFAULT_REGION: \$AWS_DEFAULT_REGION

# TimeStamp is an int value (number of seconds since 1.1.1970, will show up in the log file in a readable format)
TimeStamp=\`date \"+%s%N\" --utc\`
TimeStamp=\`expr \$TimeStamp / 1000000\`
echo TimeStamp: \$TimeStamp

# Error message we want to show in the CLoudwatch log stream
Message=\"${message}\"
echo Message: \$Message

# Cloudwatch log group and log stream must already exist!
LogGroupName=\"${log_group_trigger_name}\"
echo LogGroupName: \$LogGroupName
LogStreamName=\"${log_stream_trigger_name}\"
echo LogStreamName: \$LogStreamName

# We are getting the last upload token ('None' if it is an empty stream)
UploadSequenceToken=\$(aws logs describe-log-streams --log-group-name \"\$LogGroupName\" --query 'logStreams[?logStreamName==\`'\$LogStreamName'\`].[uploadSequenceToken]' --output text)
echo UploadSequenceToken: \$UploadSequenceToken

if [ \"\$UploadSequenceToken\" != \"None\" ]
then
  aws logs put-log-events --log-group-name \"\$LogGroupName\" --log-stream-name \"\$LogStreamName\" --log-events timestamp=\$TimeStamp,message=\"\$Message\" --sequence-token \$UploadSequenceToken
else
  # An upload in a newly created log stream does not require a sequence token.
  aws logs put-log-events --log-group-name \"\$LogGroupName\" --log-stream-name \"\$LogStreamName\" --log-events timestamp=\$TimeStamp,message=\"\$Message\"
fi
" >> $scriptdir/$scriptfile
chmod +x $scriptdir/$scriptfile

echo "... cw log script creation finished." >> /var/log/log.txt

#!/bin/bash

# Purpose:
#     Provides information about a volume.
#     Multiple volumes can be displayed if wildcard is used.
# Usage:
#     Run script with --help option to get usage.

version=1.0.0

set -o pipefail
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
script_name="$(basename "$0")"

name="$1"
profile="${AWS_PROFILE:-default}"

if [[ $1 == '--help' ]]; then
    echo 'Usage:'
    echo '    export AWS_PROFILE=profile'
    echo
    echo "    $script_name instance_name|instance_id"
    echo '    or'
    echo "    $script_name 'partial_name*'"
    exit 1
fi

# If name is not supplied, then we want all instances.
if [[ -z $name ]]; then
    name='*'
fi

date -u +'%F %T %Z'
echo "profile: $profile"
if echo "$name" | grep -q 'i-'; then
    instance_ids="$name"
else
    instance_ids=$(aws --profile "$profile" ec2 describe-instances --filters "Name=tag:Name, Values=$name" --query 'Reservations[].Instances[].[InstanceId]' --output text)
fi
echo "instance_ids:" $instance_ids
if [[ -z $instance_ids ]]; then
    exit 1
fi

for instance_id in $instance_ids; do
    echo
    aws --profile "$profile" ec2 describe-volumes --filters "Name=attachment.instance-id, Values=$instance_id" --query 'Volumes[*].{VolumeId:VolumeId,InstanceId:Attachments[0].InstanceId,State:Attachments[0].State,DeleteOnTermination:Attachments[0].DeleteOnTermination,Device:Attachments[0].Device,Size:Size}' --output table
    #aws --profile "$profile" ec2 describe-volumes --filters "Name=attachment.instance-id, Values=$instance_id" --output table
done
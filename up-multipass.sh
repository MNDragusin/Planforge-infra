#!/bin/sh

. "./config.conf"

instances=$(multipass list --format json)

instance=$(jq -c --arg name "$INSTANCE_NAME" \
    '.list[] | select(.name == $name)' \
    <<< "$instances")

if [[ -z "$instance" ]]; then
    echo "Instance '$INSTANCE_NAME' does not exist."
    
    multipass launch --name "$INSTANCE_NAME" 
fi

name=$(jq -r '.name' <<< $instance)
ip=$(jq -r '.ipv4[0]' <<< "$instance")
state=$(jq -r '.state' <<< "$instance")

echo "Name:  $name"
echo "State: $state"
echo "IP:    $ip"

if [ "$state" != "Running" ]; then
    echo "Starting instance $INSTANCE_NAME"
    multipass start "$INSTANCE_NAME"
fi

multipass transfer -r ../Planforge "$INSTANCE_NAME":/home/ubuntu/Planforge
multipass transfer ./config.conf "$INSTANCE_NAME:/home/ubuntu/config.conf"
multipass transfer ./setup.sh "$INSTANCE_NAME:/home/ubuntu/setup.sh"

multipass exec "$INSTANCE_NAME" -- bash /home/ubuntu/setup.sh 
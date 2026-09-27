#!/bin/sh

. "./config.conf"

#ubuntu LTS - 26.04
if ! limactl list --quiet | grep -qw "$INSTANCE_NAME"; then
    echo "Creating new Lima instance '$INSTANCE_NAME'..."
limactl create --name="$INSTANCE_NAME" \
    --set '.disk="20GiB"'\
    --set '.ssh.forwardAgent=true' \
    template:ubuntu
else
    echo "Instance '$INSTANCE_NAME' already exists. Skipping creation."
fi

limactl start "$INSTANCE_NAME"
limactl list --format '{{.Name}}: {{.SSHLocalPort}}'

PORT=$(limactl list "$INSTANCE_NAME" --format '{{.SSHLocalPort}}')
echo "port: $PORT"
echo "ip: $IP"

echo "Copying setup script..."
HOST_ALIAS="lima-$INSTANCE_NAME"

echo "Copying setup script..."
scp -F ~/.lima/$INSTANCE_NAME/ssh.config \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    ./setup.sh ./config.conf $HOST_ALIAS:~/

echo "Running setup script..."
ssh -A -o ForwardAgent=yes \
    -F ~/.lima/$INSTANCE_NAME/ssh.config \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    $HOST_ALIAS 'chmod +x ~/setup.sh && ~/setup.sh'

    
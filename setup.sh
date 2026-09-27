#!/bin/sh

. "./config.conf"
install_dotnet() {
    echo "Installing .NET SDK and dotnet-ef installed."
    local REAL_USER="${SUDO_USER:-$USER}"
    local REAL_HOME
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

    sudo apt-get install -y dotnet-sdk-10.0
    
    cat << EOF >> "$REAL_HOME/.bash_profile"
# Add .NET Core SDK tools
export PATH="\$PATH:\$HOME/.dotnet/tools"
EOF

sudo -u "$REAL_USER" dotnet tool install --global dotnet-ef

}

install_postgres() {
    echo "Installing postgres"
    sudo apt-get install postgresql

    echo "⏳ - Waiting for PostgreSQL to start..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASS';"

    if [ $? -eq 0 ]; then
        echo "PostgreSQL installed and postgres user password set."
    else
        echo "Failed to set postgres password."
        return 1
    fi
}

clone_repo() {
    # echo "=== SSH AGENT DEBUG ==="
    # echo "SSH_AUTH_SOCK is: ${SSH_AUTH_SOCK:-NOT_SET}"
    # ssh-add -l || echo "Failed to connect to ssh-agent or no keys found."
    # echo "======================="

    echo "Adding GitHub to known_hosts..."
    mkdir -p ~/.ssh
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    chmod 600 ~/.ssh/known_hosts

    echo "Cloaning $REPO"
    git clone "$REPO"
}

build_project() {
    cd "$PROJECT_ROOT"

    pwd
    dotnet ef database update —project Planforge.Infrastructure —startup-project Planforge.Api

    dotnet build 
    dotnet run
}

#install_dotnet
#install_postgres

dotnet --version
psql --version

#clone_repo
build_project

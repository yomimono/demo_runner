#!/bin/sh

[ "$BASEDIR" = "" ] && BASEDIR="/home/mirage"
[ "$IRMIN_WWW_CONFIG" = "" ] && IRMIN_WWW_CONFIG="${BASEDIR}/irmin-www/irmin-www.xl"
[ "$TLS_CLIENT_CONFIG" = "" ] && TLS_CLIENT_CONFIG="${BASEDIR}/example-unikernels/https-client/tls-client.xl"
[ "$GIT_SERVER_DIRECTORY" = "" ] && GIT_SERVER_DIRECTORY="${BASEDIR}/git_server_directory"
[ "$TLS_CLIENT_REPOSITORY" = "" ] && TLS_CLIENT_REPOSITORY="local_issues"

# make sure unikernels on the bridge can access the Internet, via NAT if necessary
echo "Enabling connection sharing via NAT"
sudo sysctl net/ipv4/ip_forward=1
sudo iptables -I POSTROUTING -t nat -j MASQUERADE

# make sure dnsmasq is running with current configuration
echo ""
echo "Restarting dnsmasq (to alter configuration, edit /etc/dnsmasq.conf)"
sudo killall dnsmasq; sudo dnsmasq

# start irmin-www
echo ""
echo "Starting irmin-www, the Irmin in-memory-store-backed postable demonstration server."
echo "The Irmin control interface will be accessible on port 8444; HTTPS available on port 8443."
echo "The unikernel will start paused, so you can attach a console before unpausing it if you like."
echo "When ready to run it, unpause with the following command:"
echo "sudo xl unpause irmin-www"
sudo xl create $IRMIN_WWW_CONFIG -p

# start the scraper
echo ""
echo "Starting tls-client, the automated backup client for cloud-hosted GitHub data."
echo "First, starting a local git server for the backup client to sync to..."
mkdir -p ${GIT_SERVER_DIRECTORY}/${TLS_CLIENT_REPOSITORY}
git init --bare ${GIT_SERVER_DIRECTORY}/${TLS_CLIENT_REPOSITORY}
touch ${GIT_SERVER_DIRECTORY}/${TLS_CLIENT_REPOSITORY}/git-daemon-export-ok
echo "Repository in ${GIT_SERVER_DIRECTORY}/${TLS_CLIENT_REPOSITORY} is ready to be shared via git-daemon."
git daemon --reuseaddr --base-path=${GIT_SERVER_DIRECTORY} --enable=receive-pack ${GIT_SERVER_DIRECTORY}/${TLS_CLIENT_REPOSITORY} &
echo "Local git server is running, serving ${GIT_SERVER_DIRECTORY} over port 9418."
echo "Starting the tls-client unikernel.  The unikernel will start paused, so you can start a console if you like."
echo "sudo xl unpause tls-client"
sudo xl create $TLS_CLIENT_CONFIG -p

echo ""
echo "Unikernels should now be ready to unpause."

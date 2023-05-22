#! /bin/bash
set -euxo pipefail
source /etc/os-release

if grep nfs4 /etc/fstab ; then
    echo "Nfs already mounted"
    exit 0
fi
if [  -f "$WORKINGDIR/.offline" ];then
    cd $WORKINGDIR/nfs
    if [ "$ID_LIKE" = "debian" ]; then
        dpkg -i *.deb
    else
        rpm -iUvh *.rpm
    cd $WORKINGDIR
    fi
else
    if [ "$ID_LIKE" = "debian" ]; then
        apt install -y nfs-common
    else
        yum install -y nfs-utils
    fi
fi
if [ -f "$WORKINGDIR/.multinode" ]; then
    DEP_DIR="/opt/fms/solution"
    mkdir -p $DEP_DIR
elif [ -f "$WORKINGDIR/.replica" ]; then
    DEP_DIR="/opt/fms/master"
    mkdir -p $DEP_DIR
else
    DEP_DIR="/opt/fms/solution"
    mkdir -p $DEP_DIR
fi
clear
echo "A NFS share is required to hold the FMS application files"
read -p 'Enter the IP address or hostname of the NFS server: ' SHARE_SRV
if [[ $(rpcinfo -t $SHARE_SRV nfs 4) ==  "program 100003 version 4 ready and waiting" ]];then
    NFS=nfs4
else
    NFS=nfs
fi
showmount -e $SHARE_SRV
read -p 'Enter the NFS share path displayed above: ' SHARE
#printf '\n%s   %s   nfs4    nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=60,retrans=2 0 0\n' "$SHARE" "$DEP_DIR" >> /etc/fstab
printf '\n%s:%s   %s   %s auto,nofail,noatime,nolock,intr,tcp,actimeo=1800  0 0\n' "$SHARE_SRV" "$SHARE" "$DEP_DIR" "$NFS" >> /etc/fstab
#mount -av
while  ! ( mount -a -t $NFS || true ; mountpoint "$DEP_DIR" ); do
    echo "$DEP_DIR not mounted"
    sleep 1
done
echo "$(date): NFS client installed and ${DEP_DIR} mounted" >> $LOGFILE
export DEP_DIR
touch $WORKINGDIR/.nfs
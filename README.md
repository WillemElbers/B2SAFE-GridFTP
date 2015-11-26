# Installation and Configuration

## Installing Globus 

### Installing the simpleCA

When starting out on a new system, your `/etc/grid-security` directory should look similar to this:
```
.
├── certificates
├── grid-mapfile
├── gsi.conf
└── sshftp -> /etc/gridftp-sshftp

1 directory, 3 files
```

Installing simpleCA as the root user on the GridFTP server. 
(/var/lib/globus/simple_ca)

```
$ sudo apt-get install globus-simple-ca globus-gsi-cert-utils-progs
$ grid-ca-create
<Follow prompts and make sure to remember your PEM phassphrase>
```

Your CA subject will be similar to the following:
```
CA subject: cn=Globus Simple CA, ou=simpleCA-irods4.alice, ou=GlobusTest, o=Grid
```

root@iRODS4:/etc/grid-security# ln -s /var/lib/globus/simple_ca/grid-security.conf grid-security.conf
root@iRODS4:/etc/grid-security# ln -s /var/lib/globus/simple_ca/globus-host-ssl.conf  globus-host-ssl.conf
root@iRODS4:/etc/grid-security# ln -s /var/lib/globus/simple_ca/globus-user-ssl.conf  globus-user-ssl.conf

Directory layout after setting up CA:

root@iRODS4:~# tree
.
├── globus_simple_ca_dd5d9bb8.tar.gz
└── openssl_req.log

0 directories, 2 files

root@iRODS4:/etc/grid-security# tree
.
├── certificates
│   ├── dd5d9bb8.0
│   ├── dd5d9bb8.signing_policy
│   ├── globus-host-ssl.conf.dd5d9bb8
│   ├── globus-user-ssl.conf.dd5d9bb8
│   └── grid-security.conf.dd5d9bb8
├── globus-host-ssl.conf -> certificates/globus-host-ssl.conf.dd5d9bb8
├── globus-user-ssl.conf -> certificates/globus-user-ssl.conf.dd5d9bb8
├── grid-mapfile
├── grid-security.conf -> certificates/grid-security.conf.dd5d9bb8
├── gsi.conf
└── sshftp -> /etc/gridftp-sshftp

1 directory, 11 files

Generate required certificates

generate host certificate request

root@iRODS4:~#grid-cert-request -host iRODS4.alice
root@iRODS4:~#grid-ca-sign -in /etc/grid-security/hostcert_request.pem -out /etc/grid-security/hostcert.pem

root@iRODS4:/etc/grid-security# tree
.
├── certificates
│   ├── dd5d9bb8.0
│   ├── dd5d9bb8.signing_policy
│   ├── globus-host-ssl.conf.dd5d9bb8
│   ├── globus-user-ssl.conf.dd5d9bb8
│   └── grid-security.conf.dd5d9bb8
├── globus-host-ssl.conf -> certificates/globus-host-ssl.conf.dd5d9bb8
├── globus-user-ssl.conf -> certificates/globus-user-ssl.conf.dd5d9bb8
├── grid-mapfile
├── grid-security.conf -> certificates/grid-security.conf.dd5d9bb8
├── gsi.conf
├── hostcert.pem
├── hostcert_request.pem
├── hostkey.pem
└── sshftp -> /etc/gridftp-sshftp

1 directory, 14 files

To verify/inspect the host certificate run:
 openssl x509 -in /etc/grid-security/hostcert.pem -text -noout

Generate client (user) certificate
grid-cert-request
grid-ca-sign -in /root/.globus/usercert_request.pem -out /root/.globus/usercert.pem

make sure the user certificate exists in ~/.globus/usercert.(pem|key)l

Restart grid ftp server

/etc/init.d/globus-gridftp-server restart

Setup grid map file
switch to user alice
alice@iRODS4:~# grid-cert-info -subject
/O=Grid/OU=GlobusTest/OU=simpleCA-irods4.alice/OU=local/CN=GridFTP-001

grid-mapfile-add-entry \
     -dn "/O=Grid/OU=GlobusTest/OU=simpleCA-irods4.alice/OU=local/CN=GridFTP-001" \
     -ln alice

Modifying /etc/grid-security/grid-mapfile ...
New entry:
"/O=Grid/OU=GlobusTest/OU=simpleCA-irods4.alice/OU=local/CN=GridFTP-001" alice
(1) entry added

Test setup
grid-proxy-init -verify -debug
globus-url-copy file:/home/alice/test.txt gsiftp://iRODS4.alice/tmp/test.txt
globus-url-copy -list gsiftp://iRODS4.alice/tmp/

#### References
[1] http://toolkit.globus.org/toolkit/docs/6.0/simpleca/admin/#idp32481920

## B2SAFE DSI
(http://irods.org/download/)

apt-get install build-essential make git
apt-get install libglobus-common-dev libglobus-gridftp-server-dev libglobus-gridmap-callout-error-dev

mkdir -p ~/iRODS_DSI/deploy
cd ~/iRODS_DSI
git clone https://github.com/EUDAT-B2STAGE/B2STAGE-GridFTP.git
cd B2STAGE-GridFTP
cp setup.sh.template setup.sh
vi setup.sh
<edit variables as follows>
export GLOBUS_LOCATION="/usr"
export IRODS_PATH="/usr"
#export FLAVOR=""
export DEST_LIB_DIR="/home/alice/iRODS_DSI"
export DEST_BIN_DIR="/home/alice/iRODS_DSI"
export DEST_ETC_DIR="/home/alice/iRODS_DSI"
#export IRODS_40_COMPAT=""

install irods dev tools and runtime
wget ftp://ftp.renci.org/pub/irods/releases/4.1.6/ubuntu14/irods-dev-4.1.6-ubuntu14-x86_64.deb
sudo dpkg -i irods-dev-4.1.6-ubuntu14-x86_64.deb

wget ftp://ftp.renci.org/pub/irods/releases/4.1.6/ubuntu14/irods-runtime-4.1.6-ubuntu14-x86_64.deb
sudo dpkg -i irods-runtime-4.1.6-ubuntu14-x86_64.deb

verify installed packages:
dpkg-query -l | grep irods

Compile
source setup.sh
cmake CMakeLists.txt
make

Configure

root@iRODS4:~# mkdir .irods
root@iRODS4:~# vi ~/.irods/irods_environment.json
root@iRODS4:~# cat ~/.irods/irods_environment.json
{
   "irods_host" : "localhost",
   "irods_port" : 1247,
   "irods_user_name" : "alice",
   "irods_zone_name" : "aliceZone",
   "irods_default_resource" : "demoResc"
}

init as gridftp user. Credentials: “alice:alice"

root@iRODS4:~# vi /etc/gridftp.conf
$LD_LIBRARY_PATH "$LD_LIBRARY_PATH:/home/alice/iRODS_DSI/B2STAGE-GridFTP/"
$irodsConnectAsAdmin "rods"
load_dsi_module iRODS
auth_level 4

vi /etc/init.d/globus-gridftp-server
LD_PRELOAD="$LD_PRELOAD:/usr/lib/x86_64-linux-gnu/libglobus_gridftp_server.so:/home/alice/iRODS_DSI/B2STAGE-GridFTP/libglobus_gridftp_server_iRODS.so"
export LD_PRELOAD

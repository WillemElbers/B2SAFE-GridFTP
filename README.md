# Installation and Configuration

In order to integrate GridFTP and iRODS three components are needed:

1. an iRODS server, see [1] for more information.
2. a GridFTP server, see [2] for more information.
3. the B2SAGE-iRODS DSI, see [3] for more information.

For the remainder of this guide we assume (1) an iRODS server is already installed (version 4.1.6 was used for this guide) and we'll focus on installing and configuring (2) the GridFTP server and (3) the B2STAGE-iRODS DSI.

## Installing and configuring the GridFTP server

The GridFTP server comes as part of the Globus toolkit, see [2] for more information and the installation manual. Out of the Globus toolkit we will be using the `globus-gridftp` and `globus-gsi` components.

Before you can use a GridFTP server with grid security (gsi) enabled, you must install and configure the `globus-gsi` components as described in [3]. In this guide we will use the `/etc/grid-security` directory to store all gsi related information for the host system.

When starting out on a new system (no globus toolkit installed), your `/etc/grid-security` directory should be similar to this:

```
.
├── certificates
├── grid-mapfile
├── gsi.conf
└── sshftp -> /etc/gridftp-sshftp

1 directory, 3 files
```

The gsi enabled GridFTP server needs:

1. a host certificate.
2. a user certificate for each user. 

In this guide we will explain how to generate these certificates ourselves.

### Installing the simpleCA

Download the proper Globus toolkit package for your system from http://toolkit.globus.org/toolkit/downloads/ and install this package on your system. You now should have all the globus tools available.

Installing simpleCA as the root user on the GridFTP server: 

```
$ grid-ca-create
<Follow prompts and make sure to remember your PEM phassphrase>
```

This will install the CA in `/var/lib/globus/simple_ca` with a CA subject similar to the following:

```
CA subject: cn=Globus Simple CA, ou=simpleCA-irods4.alice, ou=GlobusTest, o=Grid
```

The `grid-ca-create` command places all filed needed to install the CA in `/var/lib/globus/simple_ca/`. In order to activate this CA on this system, these files must be made available in `/etc/grid-security`. To symlink the required files run the following commands:

```
root@iRODS4:/etc/grid-security# ln -s /var/lib/globus/simple_ca/grid-security.conf grid-security.conf
root@iRODS4:/etc/grid-security# ln -s /var/lib/globus/simple_ca/globus-host-ssl.conf  globus-host-ssl.conf
root@iRODS4:/etc/grid-security# ln -s /var/lib/globus/simple_ca/globus-user-ssl.conf  globus-user-ssl.conf
```

Directory layout of your `/etc/grid-security` directory after following these instructions:

```
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
```

### Generate required certificates

With the CA setup on the system we can now generate certificate requests and sign the with our CA.

#### generate host certificate request

We will create a host certificate request:

```
root@iRODS4:~#grid-cert-request -host iRODS4.alice
```

And then we will sign the request with our CA:

```
root@iRODS4:~#grid-ca-sign -in /etc/grid-security/hostcert_request.pem -out /etc/grid-security/hostcert.pem
```

Now the `/etc/grid-security` directory should look as follows:

```
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
```

To verify or inspect the host certificate we have generated, run:

```
openssl x509 -in /etc/grid-security/hostcert.pem -text -noout
```

Restart grid ftp server:

```
/etc/init.d/globus-gridftp-server restart
```

#### Generate client (user) certificate

Users must authenticate to the GridFTP server by presenting a certificate. Again we will use our CA to sign certificate request for each user.

Generate a user certificate request:

```
grid-cert-request
```

Sign this request with our CA:

```
grid-ca-sign -in /root/.globus/usercert_request.pem -out /root/.globus/usercert.pem
```

Place the user certificate and key in the users (alice in our case) home directory under `~/.globus/usercert.(pem|key)`.

### Setup grid map file


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



#### References


### Firewall configuration
[todo]

### Test

Test setup
grid-proxy-init -verify -debug
globus-url-copy file:/home/alice/test.txt gsiftp://iRODS4.alice/tmp/test.txt
globus-url-copy -list gsiftp://iRODS4.alice/tmp/

## B2SAFE DSI

We assume iRODS 4.1.6 is installed from packages. See http://irods.org/download/ for all available downloads.

### Prepare
```
apt-get install build-essential make git
apt-get install libglobus-common-dev libglobus-gridftp-server-dev libglobus-gridmap-callout-error-dev
```

```
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
```

install irods dev tools and runtime

```
wget ftp://ftp.renci.org/pub/irods/releases/4.1.6/ubuntu14/irods-dev-4.1.6-ubuntu14-x86_64.deb
sudo dpkg -i irods-dev-4.1.6-ubuntu14-x86_64.deb

wget ftp://ftp.renci.org/pub/irods/releases/4.1.6/ubuntu14/irods-runtime-4.1.6-ubuntu14-x86_64.deb
sudo dpkg -i irods-runtime-4.1.6-ubuntu14-x86_64.deb
```

verify installed packages:

```
dpkg-query -l | grep irods
```

### Compile

```
source setup.sh
cmake CMakeLists.txt
make
```

### Configure

```
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
```

init as gridftp user. Credentials: “alice:alice"

```
root@iRODS4:~# vi /etc/gridftp.conf
$LD_LIBRARY_PATH "$LD_LIBRARY_PATH:/home/alice/iRODS_DSI/B2STAGE-GridFTP/"
$irodsConnectAsAdmin "rods"
load_dsi_module iRODS
auth_level 4
```

```
vi /etc/init.d/globus-gridftp-server
LD_PRELOAD="$LD_PRELOAD:/usr/lib/x86_64-linux-gnu/libglobus_gridftp_server.so:/home/alice/iRODS_DSI/B2STAGE-GridFTP/libglobus_gridftp_server_iRODS.so"
export LD_PRELOAD
```

### Test

## References

1. http://www.irods.org
2. http://toolkit.globus.org/toolkit/docs/6.0/admin/install/#gtadmin
3. https://github.com/EUDAT-B2STAGE/B2STAGE-GridFTP
4. http://toolkit.globus.org/toolkit/docs/6.0/simpleca/admin/#idp32481920

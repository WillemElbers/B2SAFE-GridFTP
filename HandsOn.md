# B2SAFE GridFTP Hands On

This hands on session will make you familiar with the high performant GridFTP transfer mechanism. You will learn how to install the globus-url-copy command line utility, used to tranfer data to a GridFTP server and how to develop a script for automated ingestion of data into B2SAFE using GridFTP.

Total time for this hands on is estimated at 60 minutes.
## 1: GridFTP client setup and configuration

Time: 10 minutes

### 1.1: Globus client tools installation

Install the `globus-data-management-client` from the globus package repo on your system. This will provide the Client Tools for data management, including the GridFTP client programs and globus-url-copy

Full installation instructions are available here: `http://toolkit.globus.org/toolkit/docs/6.0/admin/install/`.

#### RPM based
Download and install the package repo for your system:

```
wget http://toolkit.globus.org/ftppub/gt6/installers/repo/globus-toolkit-repo-latest.noarch.rpm && \
rpm -hUv globus-toolkit-repo-latest.noarch.rpm && \
yum install globus-data-management-client
```

#### DEB based
Download and install the package repo for your system:

```
wget http://toolkit.globus.org/ftppub/gt6/installers/repo/globus-toolkit-repo_latest_all.deb && \
dpkg -i globus-toolkit-repo_latest_all.deb && \
apt-get update && apt-get install -y globus-data-management-client
```
 
### 1.2: User certificate and proxy configuration

* Obtain your user certificate and private key from the remote server `alice` and place it in `~/.globus/`:

```
mkdir ~/.globus && \
scp alice@145.100.59.149:~/users/gridftp<xyz>/user* ~/.globus/
```

* Install the certificate for the CA that signed the user certificate (only needed for untrusted CA's):

```
mkdir /etc/grid-security/certificates && \
scp alice@145.100.59.149:~/users/ca/dd5d9bb8* /etc/grid-security/certificates/
```

* Initialize the proxy

The first time you can run the following command to get detailed information about your certificate:

```
grid-proxy-init -verify -debug
```

Normally you don't need to initialize the proxy with the `-verify` and `-debug` options. Thus the following suffices to initialize a new proxy certificate:

```
grid-proxy-init
```

Finally you have to supply the password for the user certificate and then the proxy certificate is generated. The final output will tell you when the proxy certificate will expire. By default the proxy certificate has a validity of 12 hours.

#### Additional information

The `grid-proxy-init -verify -debug` command will show some information about your user certificate and CA that signed the user certificate.

This is the user certificate and key file you just copied from the remote `alice` machine:

```
User Cert File: /root/.globus/usercert.pem
User Key File: /root/.globus/userkey.pem
```

The CA certificate and signing policy used to sign the user certificate is loaded from this directory:

```
Trusted CA Cert Dir: /etc/grid-security/certificates
```

Your proxy certificate is placed in this file:

```
Output File: /tmp/x509up_u0
```

The identity you will be using, based on the user certificate:

```
Your identity: /O=Grid/OU=GlobusTest/OU=simpleCA-irods4.alice/OU=local/CN=GridFTP-001
```

#### Issues

##### Issue 1
```
Error: Couldn't verify the authenticity of the user's credential to generate a proxy from.
       grid_proxy_init.c:956: globus_credential: Error verifying credential: Failed to verify credential
globus_gsi_callback_module: Could not verify credential
globus_gsi_callback_module: Could not verify credential
globus_gsi_callback_module: Error with signing policy
globus_gsi_callback_module: Error with signing policy
globus_sysconfig: Error getting signing policy file
globus_sysconfig: File does not exist: /etc/grid-security/certificates/dd5d9bb8.signing_policy is not a valid file
```

This error means the CA signing policy file for the user certificate is not in the expected location. Fetch the CA signing policy file from the remote `alice` server an place it in `/etc/grid-security/certificates`.

##### Issue 2

```
Error: Couldn't verify the authenticity of the user's credential to generate a proxy from.
       grid_proxy_init.c:956: globus_credential: Error verifying credential: Failed to verify credential
globus_gsi_callback_module: Could not verify credential
globus_gsi_callback_module: Can't get the local trusted CA certificate: Cannot find trusted CA certificate with hash dd5d9bb8 in /etc/grid-security/certificates
```

This error means the CA certificate is not in the expected location. Fetch the CA certificate from the remote `alice` server and place it in `/etc/grid-security/certificates`.

#### Host

```
echo "145.100.59.149 irods4.alice" >> /etc/hosts
```


## 2: Communicate with GridFTP server

Time: 10 minutes

### 2.1: Globus-url-copy

Usage of the `globus-url-copy` command:

```
# globus-url-copy -help

globus-url-copy [options] <sourceURL> <destURL>
globus-url-copy [options] -f <filename>

<sourceURL> may contain wildcard characters * ? and [ ] character ranges
in the filename only.
Any url specifying a directory must end with a forward slash '/'

If <sourceURL> is a directory, all files within that directory will
be copied.
<destURL> must be a directory if multiple files are being copied.
...
```

Some useful arguments:

```
Note:  If the ftp server from the source url does not support the MLSD
       command, this client will attempt to transfer subdirectories as
       files, resulting in an error.  Recursion is not possible in this
       case, but you can use the -c (continue on errors) option in order
       to transfer the regular files from the top level directory.
       **GridFTP servers prior to version 1.17 (Globus Toolkit 3.2)
         do not support MLSD.

OPTIONS
  -help | -usage
       Print help
  -version
       Print the version of this program
  -versions
       Print the versions of all modules that this program uses
  ...
  -cd | -create-dest
       Create destination directory if needed
  -r | -recurse
       Copy files in subdirectories
  -fast
       Recommended when using GridFTP servers. Use MODE E for all data
       transfers, including reusing data channels between list and transfer
       operations.
  -q | -quiet
       Suppress all output for successful operation
  -v | -verbose
       Display urls being transferred
  -vb | -verbose-perf
       During the transfer, display the number of bytes transferred
       and the transfer rate per second.  Show urls being transferred
  -dbg | -debugftp
       Debug ftp connections.  Prints control channel communication
       to stderr
  ...
  -rp | -relative-paths
      The path portion of ftp urls will be interpreted as relative to the
      user's starting directory on the server.  By default, all paths are
      root-relative.  When this flag is set, the path portion of the ftp url
      must start with %%2F if it designates a root-relative path.
  ...
  -list <url to list>
  ...
  -concurrency | -cc
      Number of concurrent ftp connections to use for multiple transfers.
  ...
  -sync
       Only transfer files where the destination does not exist or differs
       from the source.  -sync-level controls how to determine if files
       differ.
  -sync-level <number>
       Choose criteria for determining if files differ when performing a
       sync transfer.  Level 0 will only transfer if the destination does
       not exist.  Level 1 will transfer if the size of the destination
       does not match the size of the source.  Level 2 will transfer if
       the timestamp of the destination is older than the timestamp of the
       source, or the sizes do not match.  Level 3 will perform a checksum of
       the source and destination and transfer if the checksums do not match,
       or the sizes do not match.  The default sync level is 2.
```

### 2.1: Listing

```
globus-url-copy -list gsiftp://irods4.alice/aliceZone/home/alice
```

### 2.2: Uploading and Downloading files

## 3 Data synchronization

Time: 30 minutes

### 3.1 Client data transfer script

### 3.2 Server policies
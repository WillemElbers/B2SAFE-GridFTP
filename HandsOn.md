# B2SAFE GridFTP Hands On

This hands on session will make you familiar with the high performant GridFTP transfer mechanism. You will learn how to install the globus-url-copy command line utility, used to tranfer data to a GridFTP server and how to develop a script for automated ingestion of data into B2SAFE using GridFTP.

Total time for this hands on is estimated at 60 minutes.
## 1: GridFTP client setup and configuration

Goal: install and configure the globus-url-copy command

Time: 10 minutes

### 1.1: Globus client tools installation (local installation)

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
 
### 1.1.2: User certificate, proxy and host configuration 

Continue with this section if you want to install the globus-client-tools on your local machine. This allows you to ingest data into the B2SAFE test environment directly from your machine.

* Obtain your user certificate and private key from the remote server and place it in `~/.globus/`:

```
mkdir ~/.globus && \
scp <user>@145.100.58.133:~/user* ~/.globus/
```
Where `user` is your groups user (irods1, irods2, ...) of the client vm.

* Install the certificate for the CA that signed the user certificate (only needed for untrusted CA's):

```
mkdir /etc/grid-security/certificates && \
scp <user>@145.100.58.133:~/ca/* /etc/grid-security/certificates/
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

### 1.1.3 Host file configuration

In order to access the irods machine via its hostnames `irods4.alice` we have to add the following entry to the `/etc/hosts` file:

```
echo "145.100.59.149 irods4.alice" >> /etc/hosts
```
Note: you might need to use `sudo` to obtain write permission.

### 1.1.4 Dataset

On the client VM a simple file structure has been prepared for this tutorial. You can use your own files, but in order to follow the tutorial it might be easier to copy these files to your local machine:

```
scp -r <user>@145.100.58.133:~/gridftp* .
```

Continue with section 1.3.

### 1.2: User certificate and proxy configuration (client vm)

Continue with this section if you do not want to or cannot install the globus-client-tools on your local machine. This allows you to ingest data into the B2SAFE test environment from the client VM. If you want to ingest local data you will have to copy (scp) it to the client VM first. Credentials of the client VM are distributed during the workshop.

* Install your user certificate and private key in `~/.globus/`:

```
mkdir ~/.globus && \
cp *.pem ~/.globus/
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

Continue with section 1.3.

### 1.3 Useful proxy and certificate commands

#### grid-proxy-info

You can use the `grid-proxy-info` command to get information about the current proxy:

```
$ grid-proxy-info
subject  : /O=Grid/OU=GlobusTest/OU=simpleCA-irods4.alice/OU=local/CN=GridFTP-001/CN=1963993271
issuer   : /O=Grid/OU=GlobusTest/OU=simpleCA-irods4.alice/OU=local/CN=GridFTP-001
identity : /O=Grid/OU=GlobusTest/OU=simpleCA-irods4.alice/OU=local/CN=GridFTP-001
type     : RFC 3820 compliant impersonation proxy
strength : 1024 bits
path     : /tmp/x509up_u1001
timeleft : 8:22:56
```

#### grid-proxy-destroy
You can use the `grid-proxy-destroy` command to delete the current proxy certificate.

#### grid-cert-info
You can use the `grid-cert-info` command to display information about the current active user certificate (installed in `~/.globus/usercert.pem`).

#### grid-cert-diagnostics
You can use the `grid-cert-diagnostics` command to run some diagnostics on the certificate setup on your system and the trust chain.

### 1.4 Additional information

The `grid-proxy-init -verify -debug` command will show some information about your user certificate and CA that signed the user certificate.

This is the user certificate and key file you just copied from the remote machine:

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

### 1.5 Issues

#### Issue 1
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

#### Issue 2

```
Error: Couldn't verify the authenticity of the user's credential to generate a proxy from.
       grid_proxy_init.c:956: globus_credential: Error verifying credential: Failed to verify credential
globus_gsi_callback_module: Could not verify credential
globus_gsi_callback_module: Can't get the local trusted CA certificate: Cannot find trusted CA certificate with hash dd5d9bb8 in /etc/grid-security/certificates
```

This error means the CA certificate is not in the expected location. Fetch the CA certificate from the remote server and place it in `/etc/grid-security/certificates`.

## 2: Communicate with GridFTP server

Goal: Getting familiar with the globus-url-copy command and performing some basic GridFTP actions.

Time: 10 minutes

### 2.1: Globus-url-copy

There are many options available for the `globus-url-copy` command. This section will show the parts explaining how to use the command and some of the most relevant options for this session.
 
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
  -help | -usage
       Print help
  -version
       Print the version of this program
  -versions
       Print the versions of all modules that this program uses
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
```

```
  -list <url to list>
```

```
  -concurrency | -cc
      Number of concurrent ftp connections to use for multiple transfers.
```

```
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

In the following command examples `irods<x>` is the irods username of your group. `<x>` should be replaced with your group number.


### 2.1: Listing

Listing an iRODS collection in the remote server by using the `-list` argument.

Example:

```
globus-url-copy -ipv6 -list gsiftp://irods4.alice/aliceZone/home/irods<x>/
```

Note: don't forget the trailing slash (/).

Since this GridFTP server is integrated with iRODS, the url to list consists of `/<zone_name>/<collection>/<collection>/...`. Where the `collection` part is the logical path inside the iRODS zone.

If you want more output on what is happening use the `-dbg -v` arguments.

```
globus-url-copy -ipv6 -dbg -v -list gsiftp://irods4.alice/aliceZone/home/irods<x>/
```

This will output alot of information on the data sent to and received from the server.

### 2.2: Uploading and Downloading files

#### Single files

Transfer a single file to the remote iRODS server:

```
globus-url-copy -ipv6 -vb single_file.txt gsiftp://irods4.alice/aliceZone/home/irods<x>/
```

#### Directories

Tranfer a directory to the remote iRODS server:

```
globus-url-copy -ipv6 -vb dataset1/ gsiftp://irods4.alice/aliceZone/home/irods<x>/dataset1/
```

This command will fail with the following message because the destination directory doesn't exist:

```
500 500-Command failed. : iRODS DSI. Error: rcDataObjCreate failed. SYS_INTERNAL_NULL_INPUT_ERR: , status: -24000.
```

Questions:

* Improve the command in such a way that the destination directory is properly created.
* Improve the command in such a way that all subdirectories are included as well. 

## 3 Data synchronization

Goal: use the `globus-url-copy` command to implement a data transfer workflow using the B2SAFE service as remote storage.

Time: 30 minutes

### 3.1 Client data transfer script

The goal is to develop a script that will synchronize a directory tree from the client to the server and when run multiple times it should take into account changed and deleted files. 

* Create the data synchronization script
* Synchronize your `gridftp<xyz>` directory to `/aliceZone/home/alice/irods<x>/data/`
* Verify the data is properly updated
* Synchronize again and verify no files are transfered
* Change a file
* Synchronize again and verify the file is properly updated

### 3.2 Improved data transfer workflow

The iRODS and B2SAGE hands on session should be completed before this step.

The goal is to improve the data transfer workflow as follows:

* Configure the data transfer workflow in such a way that checksums are generated for the ingested data.
* Configure the data transfer workflow in such a way that PIDs are generated and assigned to ingested data.

#### 3.2.1 Using the icommands

You can use the `ichksum` command to generate checksums for data objects in iRODS. Alternativly you can utilize the `irule` command and invoke a rule which uses the `<todo>` microservice.

In order the mint pids you can use the `irule` command to call the B2SAFE microservices used to manage PIDs.

Usefull rules can be found in `/etc/irods/eudat3.re`.

A selection (not a complete list) of PID management rules provided via B2SAFE:

* EUDATCreatePID(*parent_pid, *path, *ror, *iCATCache, *newPID)
* EUDATPidsForColl(*collPath)
* EUDATeCHECKSUMupdate(*PID, *path)

#### 3.2.2 Using the iRODS server rule engine

A better, and more advanced, approach is to use the iRODS rule engine to compute checksums and mint PIDs automatically. This has probably not been covered in the tutorials so far, so only proceed if you are ok with some trial and error.

You can find the iRODS server rule engine configuration here: `/etc/irods/core.re`. 

Some usefull hooks in this context are:

* `acPostProcForPut` - Rule for post processing the put operation.
* `acPostProcForCopy` - Rule for post processing the copy operation.
* `acPostProcForFilePathReg` - Rule for post processing the registration
* `acPostProcForCreate` - Rule for post processing of data object create.
* `acPostProcForOpen` - Rule for post processing of data object open.
* `acPostProcForPhymv` - Rule for post processing of data object phymv.
* `acPostProcForRepl` - Rule for post processing of data object repl.

Make sure to limit the changes to the irods home directory for your user:

```
ON($objPath like "/aliceZone/home/irods<x>/*") {
	# do something useful
}
```

More information on the iRODS microservices: https://docs.irods.org/master/doxygen/

#### 3.2.3 Things to think about

* Upon ingestion of data in B2SAFE checksums are now computed, how could you obtain the checksums for data you ingest with the data transfer script?
* Upon ingestion of data in B2SAFE PIDs are now assigned, how could you obtain the PIDs for data you ingest with the data transfer script?

### 3.3 Server policies

If you completed the data transfer workflow improvements by using the iRODS rule engine you can continue with this section.

The iRODS and B2STAGE hands on sessions should be completed before this step.

The goal if to configure the alice iRODS server in such a way that ingested data is replicated to the bob iRODS server as well using the B2SAFE service.

## Appendix A: Environment

Client VM:

for each iRODS user the following layout is present:

```
/home/irods<x># tree
.
├── ca
│   ├── dd5d9bb8.0
│   └── dd5d9bb8.signing_policy
├── gridftp001
│   ├── dataset1
│   │   └── single_file.txt
│   └── dataset2
│       ├── 1.txt
│       ├── 2.txt
│       └── objects
│           └── 3.txt
├── usercert.pem
└── userkey.pem

5 directories, 8 files
```

Each certificate is named `usercert.pem` with a passphrase of the form `gridftp<xyz>`, where `<xyz>` is the respective group number.

"remote" AliceZone:

```
/aliceZone/home/alice:
  C- /aliceZone/home/alice/gridftp001
  C- /aliceZone/home/alice/gridftp002
  C- /aliceZone/home/alice/gridftp003
  C- /aliceZone/home/alice/gridftp004
  C- /aliceZone/home/alice/gridftp005
  C- /aliceZone/home/alice/gridftp006
  C- /aliceZone/home/alice/gridftp007
  C- /aliceZone/home/alice/gridftp008
  C- /aliceZone/home/alice/gridftp009
  C- /aliceZone/home/alice/gridftp010
```
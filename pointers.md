# 3.1 Client data transfer script

The goal is to develop a script that will synchronize a directory tree from the client to the server and when run multiple times it should take into account changed files. You should also consider expiration for the proxy certificate and renew it when needed.

The `-sync` option (together with the `-sync-level` option) is a good fit for this use case. 

Input arguments: 

* directory on the local filesystem (source_path)
* remote directory (dest_collection)

The remote zone (zone) will be hardcoded into the script.


Example script usage:

```
data-transfer.sh <source_path> <dest_collection>

Options:
	-v verbose
	-l	synchronization level, defaults to 2
			Level 0 will only transfer if the destination does not exist
			Level 1 will transfer if the size of the destination does not match the size of the source.
			Level 2 will transfer if the timestamp of the destination is older than the timestamp of 
				the source, or the sizes do not match.
			Level 3 will perform a checksum of the source and destination and transfer if the checksums 
				do not match, or the sizes do not match.
	-h 		This help
```

Example synchronizing a local directory to B2SAFE:

```
./data-transfer.sh -v /home/alice/gridftp-handson/gridftp001/ /home/alice/gridftp001/
```

Things to consider for further improvements:

* Don't fail on errors (but output to log file)
* Retry in case of failures
* Control remote destination iRODS storage resource
* Delete remote files if they are locally removed.
  *  Is this easily possible?
  *  Could you utilize the icommands?
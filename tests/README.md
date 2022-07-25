# RSE Data management tests

## Direct Access to the RSE Endpoint

In order to run and to measure the data access quality of the your RSE you can execute the next:

```
sh rse-direct-access.sh
```

The ouput will be like `time-<size>MB.<operation>.ts` where <size> is the size of the file to store/get/remove, and the operation will be `put`, `get`, or `rm`, to upload, download or delete a file to/from our RSE. You will get the time of each operation in each file.


## Third Party Copies

In order to execute submissions for file uploads between a RSE to another using FTS:

```
sh rse-fts-tpc.sh
```

The ouput will be like `time-<size>MB.<operation>.ts` where <size> is the size of the file to store/get/remove, and the operation will be `put`, `get`, or `rm`, to upload, download or delete a file to/from our RSE. You will get the time of each operation in each file.



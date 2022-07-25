TOKEN=""
URL="https://spsrc14.iaa.csic.es:18027/disk"

# 1000 MB
dd if=/dev/zero of=testfile bs=1024 count=1024000

davix-ls --insecure  -l -H "Authorization: Bearer $TOKEN" $URL/;
{ time davix-put --insecure  -H "Authorization: Bearer $TOKEN" testfile  $URL/testfile ; } 2> time-1000MB.put.ts
{ time davix-get --insecure -H "Authorization: Bearer $TOKEN" $URL/testfile testfile.downloaded ; } 2> time-1000MB.get.ts
{ time davix-rm --insecure  -H "Authorization: Bearer $TOKEN" $URL/testfile ; } 2> time-1000MB.rm.ts

# 500 MB
dd if=/dev/zero of=testfile bs=1024 count=512000

davix-ls --insecure  -l -H "Authorization: Bearer $TOKEN" $URL/;
{ time davix-put --insecure  -H "Authorization: Bearer $TOKEN" testfile  $URL/testfile ; } 2> time-500MB.put.ts
{ time davix-get --insecure -H "Authorization: Bearer $TOKEN" $URL/testfile testfile.downloaded ; } 2> time-500MB.get.ts
{ time davix-rm --insecure  -H "Authorization: Bearer $TOKEN" $URL/testfile ; } 2> time-500MB.rm.ts


# 100 MB
dd if=/dev/zero of=testfile bs=1024 count=102400

davix-ls --insecure  -l -H "Authorization: Bearer $TOKEN" $URL/;
{ time davix-put --insecure  -H "Authorization: Bearer $TOKEN" testfile  $URL/testfile ; } 2> time-100MB.put.ts
{ time davix-get --insecure -H "Authorization: Bearer $TOKEN" $URL/testfile testfile.downloaded ; } 2> time-100MB.get.ts
{ time davix-rm --insecure  -H "Authorization: Bearer $TOKEN" $URL/testfile ; } 2> time-100MB.rm.ts

# 10 MB
dd if=/dev/zero of=testfile bs=1024 count=10240

davix-ls --insecure  -l -H "Authorization: Bearer $TOKEN" $URL/; 
{ davix-put --insecure  -H "Authorization: Bearer $TOKEN" testfile  $URL/testfile ; } 2> time-10MB.put.ts
{ davix-get --insecure -H "Authorization: Bearer $TOKEN" $URL/testfile testfile.downloaded ; } 2> time-10MB.get.ts
{ davix-rm --insecure  -H "Authorization: Bearer $TOKEN" $URL/testfile ; } 2> time-10MB.rm.ts

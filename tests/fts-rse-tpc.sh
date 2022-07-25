TOKEN=""
URL=""

# 1000 MB
dd if=/dev/zero of=testfile bs=1024 count=1024000

{ time fts-rest-transfer-submit --insecure --access-token=$TOKEN -s https://fts3-pilot.cern.ch:8446/ $URL/testfile https://srcdev.skatelescope.org/storm/sa/coral_test/ ; } 2> fts-time-1000MB.put.ts
{ time fts-rest-delete-submit --insecure --access-token=$TOKEN -s https://fts3-pilot.cern.ch:8446/ https://srcdev.skatelescope.org/storm/sa/coral_test/testfile ; } 2> fts-time-1000MB.get.ts

# 500 MB
dd if=/dev/zero of=testfile bs=1024 count=512000

{ time fts-rest-transfer-submit --insecure --access-token=$TOKEN -s https://fts3-pilot.cern.ch:8446/ $URL/testfile https://srcdev.skatelescope.org/storm/sa/coral_test/ ; } 2> fts-time-500MB.put.ts
{ time fts-rest-delete-submit --insecure --access-token=$TOKEN -s https://fts3-pilot.cern.ch:8446/ https://srcdev.skatelescope.org/storm/sa/coral_test/testfile ; } 2> fts-time-500MB.get.ts

# 100 MB
dd if=/dev/zero of=testfile bs=1024 count=102400

{ time fts-rest-transfer-submit --insecure --access-token=$TOKEN -s https://fts3-pilot.cern.ch:8446/ $URL/testfile https://srcdev.skatelescope.org/storm/sa/coral_test/ ; } 2> fts-time-100MB.put.ts
{ time fts-rest-delete-submit --insecure --access-token=$TOKEN -s https://fts3-pilot.cern.ch:8446/ https://srcdev.skatelescope.org/storm/sa/coral_test/testfile ; } 2> fts-time-100MB.get.ts

# 10 MB
dd if=/dev/zero of=testfile bs=1024 count=10240

{ time fts-rest-transfer-submit --insecure --access-token=$TOKEN -s https://fts3-pilot.cern.ch:8446/ $URL/testfile https://srcdev.skatelescope.org/storm/sa/coral_test/ ; } 2> fts-time-10MB.put.ts
{ time fts-rest-delete-submit --insecure --access-token=$TOKEN -s https://fts3-pilot.cern.ch:8446/ https://srcdev.skatelescope.org/storm/sa/coral_test/testfile ; } 2> fts-time-10MB.get.ts


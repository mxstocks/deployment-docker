# Who Calls Who (in production - the test code also calls into here but never runs in prod)
memsql-report-kubectl.sh
+--> memsql-report-main.sh
     +--> memsql-report-collect-local.sh    // run parallel
     +--> memsql-report-collect.sh          // run once

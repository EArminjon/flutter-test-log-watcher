# flutter-test-log-watcher

Watch flutter test log to detect any unexpected logs

# Why this scripts ? 

On project, most of the time a try / catch print the error and return null or a generic error.
Sometimes the error is expected during test because we will mock a service and test if the exception is well catched / managed.

Sometimes a bad test can not fully test the error or some unexpected log can appear without breaking the unit test.

This script can be used to watch flutter test logs and detect potentials errors.

# Usage

Just replace
```
flutter test
```

by 
```
./test.sh
```

You can pass it every arguments you want as for the flutter test command.

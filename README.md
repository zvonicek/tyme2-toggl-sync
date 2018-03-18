# Tyme2 Toggl Sync

> Sync Tyme2 entries to Toggl using AppleScript

Script fetches [Tyme2](http://tyme-app.com/) work entries from previous workday and syncs them to Toggl using the Toggl REST API. Toggl workspace is matched by Tyme project name. `Billed` property on Tyme2 time entry is leveraged to store the status of sync, scripts sets it to `true` when synced to prevent duplicate time entry synchronization.

# How to use

Set the `togglAPIToken` property to your Toggl API token. Schedule the script so it runs once every workday (Mo-Fr). I use [Scheduler](http://www.macscheduler.net/) for this.

## Thanks to

[tyme2-standup](https://github.com/craig-davis/tyme2-standup) project for demonstration of Tyme2 AppleScript use.

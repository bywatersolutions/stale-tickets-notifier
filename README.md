# Stale Tickets Notifier

A script to to notify users about stale tickets in RT via Slack with per-user configurable options

## How to install and configure

First, you will need to create a yaml file of users to notify like so:
```yaml
users:
  - rt_owner: kyle
    slack_name: kylemhall
    days_until_stale: 7
  - rt_owner: nick
    slack_name: nick
    days_until_stale: 14
  - rt_owner: lucas
    slack_name: lucas
    days_until_stale: 14
```
`rt_owner` is the user login name in RT.
`slack_name` is the slack "name", it is *not* the Slack display name.
`days_until_stale` is the number of days since the last time the ticket was touched by anyone.

In addition, you will need to fill in the script parameters:
```
stale-tickets-notifier.pl
	-c --config            Path to config yaml
	--rt-url               RT URL
	--rt-username          RT username
	--rt-password          RT password

	--slack-bot-token      Slack Bot Token

	-v --verbose           Print extra stuff
	-h --help              Print usage message and exit
```

This script requires a Slack bot to be created that can access your Slack channels.

# Stale Tickets Notifier

A script to to notify users about stale tickets in RT via Slack with per-user configurable options

## How to install and configure

First, you will need to create a yaml file of users to notify like so:
```yaml
users:
  - rt_owner: kyle
    slack_webhook => 'https://hooks.slack.com/services/...'
    days_until_stale: 7
  - rt_owner: nick
    slack_webhook => 'https://hooks.slack.com/services/...'
    days_until_stale: 14
  - rt_owner: lucas
    slack_webhook => 'https://hooks.slack.com/services/...'
    days_until_stale: 14
```
`rt_owner` is the user login name in RT.
`slack_webhook` is the generated webhook for this user. Could be a channel or a DM.
`days_until_stale` is the number of days since the last time the ticket was touched by anyone.

In addition, you will need to fill in the script parameters:
```
stale-tickets-notifier.pl
	-c --config            Path to config yaml
	--rt-url               RT URL
	--rt-username          RT username
	--rt-password          RT password

	-v --verbose           Print extra stuff ( use multiple times for more verbosity )
	-h --help              Print usage message and exit
```

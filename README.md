# Stale Tickets Notifier

A script to to notify users about stale tickets in RT via Slack with per-user configurable options

## How to install and configure

First, you will need to create `config.yml` which describes users to notify like so:
```yaml
---
users:
    kyle@bywatersolutions.com:
        rt_owner: kyle
        days_until_stale: 7
    nick@bywatersolutions.com:
        rt_owner: nick
        days_until_stale: 14
    lucas@bywatersolutions.com:
        rt_owner: lucas
        days_until_stale: 14
```

* The `users` key is the user's email address in their Slack profile.
* `rt_owner` is the user login name in RT.
* `days_until_stale` is the number of days since the last time the ticket was touched by anyone.

In addition, the following environment variables must be set:
* `RT_URL` - The base URL for your Request Tracker server
* `RT_USER` - The user to log in as to run queries
* `RT_PW` - The password of the user to log in as
* `SLACK_API_TOKEN` - OAuth Access Token from Slack
* `SLACK_BOT_TOKEN` - Bot User OAuth Access Token from Slack

To run from Docker, execute the following:
`docker run --env-file=/path/to/stale-tickets-notifier.env -v /path/to/config.yml:/app/config.yml quay.io/bywatersolutions/stale-tickets-notifier`

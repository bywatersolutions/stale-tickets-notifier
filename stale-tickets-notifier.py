#!/usr/bin/env python3

from urllib import request
import os
import rt
import slack
import ssl
import yaml

rt_password = os.environ["RT_PW"]
rt_url = os.environ["RT_URL"]
rt_username = os.environ["RT_USER"]
slack_token = os.environ["SLACK_API_TOKEN"]
slack_bot_token = os.environ["SLACK_BOT_TOKEN"]
conf_url = os.environ["CONF_URL"]

ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

client = slack.WebClient(
    token=slack_token,
    ssl=ssl_context
)

bot = slack.WebClient(
    token=slack_bot_token,
    ssl=ssl_context
)

tracker = rt.Rt(rt_url + "/REST/1.0/", rt_username, rt_password)
tracker.login()

with open(r'config.yml') as file:
    config = yaml.load(file, Loader=yaml.FullLoader)

    y = urllib.request.urlopen(conf_url)
    config = yaml.load(y, Loader=yaml.FullLoader)

# Build dict of email => id
users = client.users_list()
my_users = {}
for m in users["members"]:
    id = m['id']
    profile = m['profile']
    if 'email' in profile:
        email = profile['email']
        my_users[email] = id

for email, data in config["users"].items():
    print(f"Working on {email}")
    days_until_stale = data["days_until_stale"]
    print(f'Days Until Stale: {days_until_stale}')
    rt_owner = data["rt_owner"]
    print(f'RT Owner: {rt_owner}')
    results = tracker.search(
        Queue='Support',
        raw_query=f"Owner = '{rt_owner}' AND Told < '{days_until_stale} days ago' AND ( Status = 'open' OR Status = 'needsinfo' OR Status = 'new' )"
    )

    print(f"Found {len(results)} tickets for {email}")
    attachments = []
    for r in results:
        print(f"  RT {r['numerical_id']}")
        title = f"<{rt_url}/Ticket/Display.html?id={r['numerical_id']}|{r['numerical_id']}: {r['Subject']}>"
        attachments.append(
            {
                'title': title,
                'fields': [
                    {
                        'title': 'Last touched',
                        'value': r['Told'],
                        'short': True,
                    }
                ]
            }
        )

    if ( len(attachments) ):
        r = bot.chat_postMessage(
            channel=my_users[email],
            text=f"Stale Tickets!",
            attachments=attachments,
        )

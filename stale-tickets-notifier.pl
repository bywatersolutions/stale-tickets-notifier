#!/usr/bin/env perl

use Modern::Perl;

use Carp::Always;
use Getopt::Long::Descriptive;
use RT::Client::REST;
use Slack::RTM::Bot;
use Term::ANSIColor;
use Try::Tiny;
use YAML;

my ( $opt, $usage ) = describe_options(
    'stale-tickets-notifier.pl',
    [
        "config|c=s",
        "Path to config yaml",
        {
            required => 1,
            default  => "/config.yml"
        },
    ],
    [ "rt-url=s", "BWS RT URL", { required => 1, default => $ENV{RT_URL} } ],
    [
        "rt-username=s",
        "BWS RT username",
        { required => 1, default => $ENV{RT_USER} }
    ],
    [
        "rt-password=s",
        "BWS RT password",
        { required => 1, default => $ENV{RT_PW} }
    ],
    [],
    [
        "slack-bot-token=s",
        "Slack Bot Token",
        { required => 0, default => $ENV{SLACK_BOT_TOKEN} }
    ],
    [],
    [ 'verbose|v+', "Print extra stuff" ],
    [ 'help|h', "Print usage message and exit", { shortcircuit => 1 } ],
);

print( $usage->text ), exit if $opt->help;

my $config = YAML::LoadFile( $opt->config );

my $verbose = $opt->verbose || 0;

my $slackbot = Slack::RTM::Bot->new( token => $opt->slack_bot_token );
$slackbot->start_RTM( sub { } );

my $rt_url  = $opt->rt_url;
my $rt_user = $opt->rt_username;
my $rt_pass = $opt->rt_password;

my $rt = RT::Client::REST->new(
    server  => $rt_url,
    timeout => 30,
);
try {
    $rt->login( username => $rt_user, password => $rt_pass );
}
catch {
    die "Problem logging in: ", shift->message;
};

say colored( 'Finding stale tickets', 'green' ) if $verbose;
foreach my $user ( @{ $config->{users}} ) {
    say "Working on " . colored( $user->{slack_name}, 'cyan' )
          if $verbose > 1;

    my $rt_query = qq{
        Queue = 'Support'
          AND
        Owner = '$user->{rt_owner}'
          AND
        Told < '$user->{days_until_stale} days ago'
          AND (
            Status = 'open'
              OR
            Status = 'needsinfo'
              OR
            Status = 'new'
        )
    };
    my @ids = $rt->search(
        type    => 'ticket',
        query   => $rt_query,
        orderby => '-id',
    );

    foreach my $ticket_id (@ids) {
        sleep(1);    # pause for 1 second between requests so we don't kill RT
        my $ticket = $rt->show( type => 'ticket', id => $ticket_id );

        say "  Ticket " . colored( $ticket_id, 'yellow' )
          if $verbose > 1;
        $slackbot->say(
            channel => '@' . $user->{slack_name},
            text    => "STALE TICKET: "
              . "<$rt_url/Ticket/Display.html?id=$ticket_id|$ticket_id: $ticket->{Subject}>"
              . ", last updated $ticket->{Told}",
        );
    }
}

say colored( 'Finished!', 'green' ) if $verbose;

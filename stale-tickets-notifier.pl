#!/usr/bin/env perl

use Modern::Perl;

use Data::Dumper;
use Carp::Always;
use Getopt::Long::Descriptive;
use JSON;
use LWP::UserAgent;
use RT::Client::REST;
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
    [],
    [
        "slack-oauth-access-token|s=s",
        "Slack OAuth Access Token",
        { required => 1, default => $ENV{SLACK_OAUTH_ACCESS_TOKEN} }
    ],
    [
        "slack-team-id|t=s",
        "Slack Team Id",
        { required => 1, default => $ENV{SLACK_TEAM_ID} }
    ],
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
    [],
    [ 'verbose|v+', "Print extra stuff" ],
    [ 'help|h', "Print usage message and exit", { shortcircuit => 1 } ],
);

print( $usage->text ), exit if $opt->help;

my $config = YAML::LoadFile( $opt->config );

my $ua = LWP::UserAgent->new;

my $users_list = get_users_list($opt);

my $verbose = $opt->verbose || 0;

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
foreach my $user ( @{ $config->{users} } ) {
    say "Working on " . colored( $user->{rt_owner}, 'cyan' )
      if $verbose > 1;

    my $slack_user_id = get_slack_id_from_email( $user->{email}, $users_list );
    unless ( $slack_user_id ) {
        say colored( "Could not find Slack id for email address: $user->{email}", 'red' );
        next;
    }

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
        sleep(1);    # pause for 1 second between requests so we don't kill RT, Slack also as a 1 per second rate limit
        my $ticket = $rt->show( type => 'ticket', id => $ticket_id );

        say "  Ticket " . colored( $ticket_id, 'yellow' )
          if $verbose > 1;

        my $title = "<$rt_url/Ticket/Display.html?id=$ticket_id|$ticket_id: $ticket->{Subject}>";
        my $response = $ua->post(
            'https://slack.com/api/chat.postMessage',
                {
                    token       => $opt->slack_oauth_access_token,
                    channel     => $slack_user_id,
                    as_user     => JSON::true,
                    text        => "Stale Ticket!",
                    attachments => [
                        {
                            title  => $title,
                            fields => [
                                {
                                    title => "Last touched",
                                    value => "$ticket->{Told}",
                                    short => JSON::true
                                },
                            ],
                        },
                    ]
                }
        );

        if ( $response->is_success ) {
            say "RESPONSE: " . Data::Dumper::Dumper( from_json( $response->decoded_content ) ) if $verbose > 2;
        }
        else {
            die $response->status_line;
        }
    }
}

say colored( 'Finished!', 'green' ) if $verbose;

sub get_users_list {
    my ($opt)   = @_;
    my $token   = $opt->slack_oauth_access_token;
    my $team_id = $opt->slack_team_id;

    my $ua   = LWP::UserAgent->new;
    my $url  = 'https://slack.com/api/users.list';
    my $data = {
        token          => $token,
        team_id        => $team_id,
        include_locale => JSON::true,
    };
    my $response = $ua->post( $url, $data );

    if ( $response->is_success ) {
        my $users_list = from_json( $response->decoded_content );
        my $members    = $users_list->{members};
        return $members;
    }
    else {
        die $response->status_line;
    }
}

sub get_slack_id_from_email {
    my ( $email, $users_list ) = @_;

    my ($user) = grep { $_->{profile}->{email} } @$users_list;
    die Data::Dumper::Dumper( grep { $_->{profile}->{email} } @$users_list );

    return $user->{id};
}

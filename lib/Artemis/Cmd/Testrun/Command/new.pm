package Artemis::Cmd::Testrun::Command::new;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::Cmd::Testrun;
use Data::Dumper;
use DateTime::Format::Natural;
require Artemis::Schema::TestrunDB::Result::Topic;

sub abstract {
        'Create a new testrun'
}

sub opt_spec {
        return (
                [ "verbose",            "some more informational output"                                                                    ],
                [ "notes=s",            "TEXT; notes"                                                                                       ],
                [ "shortname=s",        "TEXT; shortname"                                                                                   ],
                [ "topic=s",            "STRING, default=Misc; one of: Kernel, Xen, KVM, Hardware, Distribution, Benchmark, Software, Misc" ],
                [ "test_program=s",     "STRING; full path to the test program to start"                                                    ],
                [ "hostname=s",         "INT; the hostname on which the test should be run"                                                 ],
                [ "owner=s",            "STRING, default=\$USER; user login name"                                                           ],
                [ "wait_after_tests=s", "BOOL, default=0; wait after testrun for human investigation"                                       ],
                [ "earliest=s",         "STRING, default=now; don't start testrun before this time (format: YYYY-MM-DD hh:mm:ss or now)"    ],
                [ "precondition=s@",    "assigned precondition ids"                                                                         ],
                [ "macroprecond=s",     "STRING, use this macro precondition file"                                                          ],
                [ "macrovalue=s%",      "Define a key=value pair used in macro preconditions"                                               ],
               );
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns new --test_program=s --hostname=s [ --topic=s --notes=s | --shortname=s | --owner=s | --wait_after_tests=s ]*";
}

sub _allowed_opts
{
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub convert_format_datetime_natural
{
        my ($self, $opt, $args) = @_;
        # handle natural datetimes
        if ($opt->{earliest}) {
                my $parser = DateTime::Format::Natural->new;
                my $dt = $parser->parse_datetime($opt->{earliest});
                if ($parser->success) {
                        print("%02d.%02d.%4d %02d:%02d:%02d\n", $dt->day,
                              $dt->month,
                              $dt->year,
                              $dt->hour,
                              $dt->min,
                              $dt->sec) if $opt->{verbose};
                        $opt->{earliest} = $dt;
                } else {
                        die $parser->error;
                }
        }
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);

        say "Missing argument --test_program"               unless  $opt->{test_program};
        say "Missing argument --hostname"                   unless  $opt->{hostname};
        say "Do not mix --precondition with --macroprecond" if     ($opt->{macroprecond} and $opt->{precondition});

        # -- topic constraints --
        my $topic    = $opt->{topic} || '';
        my $topic_re = '('.join('|', keys %Artemis::Schema::TestrunDB::Result::Topic::topic_description).')';
        my $topic_ok = (!$topic || ($topic =~ /^$topic_re$/)) ? 1 : 0;
        print "Topic must match $topic_re.\n\n" unless $topic_ok;

        # -- precond vs. macro precond --
        my $precond_ok = $opt->{macroprecond} and $opt->{precondition} ? 0 : 1;

        $self->convert_format_datetime_natural;

        return 1 if $opt->{test_program} && $opt->{hostname} && $topic_ok && $precond_ok;

        die $self->usage->text;
}

sub run {
        my ($self, $opt, $args) = @_;

        require Artemis;

        $self->new_runtest ($opt, $args);
}

sub new_runtest
{
        my ($self, $opt, $args) = @_;

        #print "opt  = ", Dumper($opt);

        my $notes        = $opt->{notes}        || '';
        my $shortname    = $opt->{shortname}    || '';
        my $topic_name   = $opt->{topic}        || 'Misc';
        my $date         = $opt->{earliest}     || DateTime->now;
        my $test_program = $opt->{test_program};
        my $hostname     = $opt->{hostname};
        my $owner        = $opt->{owner}        || $ENV{USER};

        my $hardwaredb_systems_id = Artemis::Cmd::Testrun::_get_systems_id_for_hostname( $hostname );
        my $owner_user_id         = Artemis::Cmd::Testrun::_get_user_id_for_login( $owner );

        my $testrun = model('TestrunDB')->resultset('Testrun')->new
            ({
              notes                 => $notes,
              shortname             => $shortname,
              topic_name            => $topic_name,
              test_program          => $test_program,
              starttime_earliest    => $date,
              owner_user_id         => $owner_user_id,
              hardwaredb_systems_id => $hardwaredb_systems_id,
             });
        $testrun->insert;
        $self->assign_preconditions($opt, $args, $testrun);
        print $opt->{verbose} ? $testrun->to_string : $testrun->id, "\n";
}

sub assign_preconditions {
        my ($self, $opt, $args, $testrun) = @_;

        my @ids = @{ $opt->{precondition} || [] };

        my $succession = 1;
        foreach (@ids) {
                my $testrun_precondition = model('TestrunDB')->resultset('TestrunPrecondition')->new
                    ({
                      testrun_id      => $testrun->id,
                      precondition_id => $_,
                      succession      => $succession,
                     });
                $testrun_precondition->insert;
                $succession++
        }
}


# perl -Ilib bin/artemis-testrun new --topic=Software --test_program=/usr/local/share/artemis/testsuites/perfmon/t/do_test.sh --hostname=iring

1;

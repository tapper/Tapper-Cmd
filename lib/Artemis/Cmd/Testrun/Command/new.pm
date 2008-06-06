package Artemis::Cmd::Testrun::Command::new;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Cmd::Testrun;
use Data::Dumper;

sub opt_spec {
        return (
                [ "verbose",            "some more informational output"                                                                        ],
                [ "notes=s",            "TEXT; notes"                                                                                           ],
                [ "shortname=s",        "TEXT; shortname"                                                                                       ],
                [ "topic=s",            "STRING, default=Misc; one of: Kernel, Xen, KVM, Hardware, Distribution, Benchmark, Software, Misc"     ],
                [ "test_program=s",     "STRING; full path to the test program to start"                                                        ],
                [ "hostname=s",         "INT; the hostname on which the test should be run"                                                     ],
                [ "owner=s",            "STRING, default=\$USER; user login name"                                                               ],
                [ "wait_after_tests=s", "BOOL, default=0; wait after testrun for human investigation"                                           ],
                [ "precondition=s@",    "assigned precondition ids"                                                                             ],
               );
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns new --topic=s --test_program=s --hostname=s [ --notes=s | --shortname=s | --owner=s | --wait_after_tests=s ]*";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

#         print "opt  = ", Dumper($opt);
#         print "args = ", Dumper($args);

        print "Missing argument --topic\n"        unless $opt->{topic};
        print "Missing argument --test_program\n" unless $opt->{test_program};
        print "Missing argument --hostname\n"     unless $opt->{hostname};

        return 1 if $opt->{topic} && $opt->{test_program} && $opt->{hostname};
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
        my $test_program = $opt->{test_program};
        my $hostname     = $opt->{hostname};
        my $owner        = $opt->{owner}        || $ENV{USER};

        my $hardwaredb_systems_id = Artemis::Cmd::Testrun::_get_systems_id_for_hostname( $hostname );
        my $owner_user          = Artemis::Cmd::Testrun::_get_user_for_login( $owner );
        my $owner_user_id       = $owner_user ? $owner_user->id : undef;

        my $testrun = Artemis->model('TestrunDB')->resultset('Testrun')->new
            ({
              notes                 => $notes,
              shortname             => $shortname,
              topic_name            => $topic_name,
              test_program          => $test_program,
              owner_user_id         => ($owner_user_id || ''),
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
                my $testrun_precondition = Artemis->model('TestrunDB')->resultset('TestrunPrecondition')->new
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

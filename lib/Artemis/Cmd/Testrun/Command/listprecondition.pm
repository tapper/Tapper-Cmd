package Artemis::Cmd::Testrun::Command::listprecondition;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Data::Dumper;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;

sub opt_spec {
        return (
                [ "verbose",         "some more informational output"                      ],
                [ "nonewlines",      "escape newlines in values to avoid multilines"       ],
                [ "quotevalues",     "put quotes around the values"                        ],
                [ "colnames",        "print out column names"                              ],
                [ "all",             "list all testruns",                                  ],
                [ "lonely",          "neither a preprecondition nor assigned to a testrun" ],
                [ "primary",         "assigned to one or more testruns"                    ],
                [ "pre",             "only prepreconditions not assigned to a testrun",    ],
                [ "id=s@",           "list particular precondition",                       ],
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns list [ " . $allowed_opts ." ]";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub _extract_bare_option_names {
        map { s/=.*//; $_} _allowed_opts();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

#         print "opt  = ", Dumper($opt);
#         print "args = ", Dumper($args);

        my $allowed_opts_re = join '|', _extract_bare_option_names();

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage->text;
}

sub run {
        my ($self, $opt, $args) = @_;

        $self->$_ ($opt, $args) foreach grep /^all|lonely|primary|pre|id$/, keys %$opt;
}

sub print_colnames
{
        my ($self, $opt, $args) = @_;

        return unless $opt->{colnames};

        my $columns = model('TestrunDB')->resultset('Precondition')->result_source->{_ordered_columns};
        print join( $Artemis::Schema::TestrunDB::DELIM, @$columns, '' ), "\n";
}

sub all
{
        my ($self, $opt, $args) = @_;

        print "All testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $preconditions = model('TestrunDB')->resultset('Precondition')->all_preconditions->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                print $precond->to_string($opt)."\n";
        }
}

sub lonely
{
        my ($self, $opt, $args) = @_;

        print "Queued testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        print "Implement me. Now!\n";
        return;

        my $preconditions = model('TestrunDB')->resultset('Precondition')->lonely_preconditions->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                print $precond->to_string($opt)."\n";
        }
}

sub primary
{
        my ($self, $opt, $args) = @_;

        print "Running testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        print "Implement me. Now!\n";
        return;

        my $preconditions = model('TestrunDB')->resultset('Precondition')->primary_preconditions->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                print $precond->to_string($opt)."\n";
        }
}

sub pre
{
        my ($self, $opt, $args) = @_;

        print "Finished testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        print "Implement me. Now!\n";
        return;

        my $preconditions = model('TestrunDB')->resultset('Precondition')->pre_preconditions->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                print $precond->to_string($opt)."\n";
        }
}

sub id
{
        my ($self, $opt, $args) = @_;

        my @ids = @{ $opt->{id} };

        $self->print_colnames($opt, $args);
        print _get_testrun_by_id($_)->to_string($opt)."\n" foreach @ids;
}

# --------------------------------------------------

sub _get_testrun_by_id {
        my ($id) = @_;
        model('TestrunDB')->resultset('Precondition')->find($id);
}

1;

# perl -Ilib bin/artemis-testrun listprecondition --all --colnames
# perl -Ilib bin/artemis-testrun listprecondition --all --colnames --nonewlines 
# perl -Ilib bin/artemis-testrun listprecondition --all --colnames --nonewlines --quotevalues

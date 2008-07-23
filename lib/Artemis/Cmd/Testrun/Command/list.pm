package Artemis::Cmd::Testrun::Command::list;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Data::Dumper;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;

sub abstract {
        'List testruns'
}

sub opt_spec {
        return (
                [ "verbose",  "some more informational output" ],
                [ "colnames", "print out column names"         ],
                [ "all",      "list all testruns",             ],
                [ "finished", "list finished testruns"         ],
                [ "running",  "list running testruns"          ],
                [ "queued",   "list queued testruns",          ],
                [ "due",      "list due testruns",             ],
                [ "id=s@",    "list particular testruns",      ],
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

        $self->$_ ($opt, $args) foreach grep /^all|finished|running|queued|due|id$/, keys %$opt;
}

sub print_colnames
{
        my ($self, $opt, $args) = @_;

        return unless $opt->{colnames};

        my $columns = model('TestrunDB')->resultset('Testrun')->result_source->{_ordered_columns};
        print join( $Artemis::Schema::TestrunDB::DELIM, @$columns, '' ), "\n";
}

sub all
{
        my ($self, $opt, $args) = @_;

        print "All testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->all_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub queued
{
        my ($self, $opt, $args) = @_;

        print "Queued testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->queued_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub due
{
        my ($self, $opt, $args) = @_;

        print "Due testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->due_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub running
{
        my ($self, $opt, $args) = @_;

        print "Running testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->running_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub finished
{
        my ($self, $opt, $args) = @_;

        print "Finished testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->finished_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub id
{
        my ($self, $opt, $args) = @_;

        my @ids = @{ $opt->{id} };

        $self->print_colnames($opt, $args);
        print _get_entry_by_id($_)->to_string."\n" foreach @ids;
}

# --------------------------------------------------

sub _get_entry_by_id {
        my ($id) = @_;
        model('TestrunDB')->resultset('Testrun')->find($id);
}

1;

# perl -Ilib bin/artemis-testrun list --id 16

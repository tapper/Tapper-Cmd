package Tapper::Cmd::Scenario;

use warnings;
use strict;
use 5.010;
use Moose;

use YAML::XS;
use Tapper::Model 'model';
use parent 'Tapper::Cmd';

use Tapper::Cmd::Testrun;


=head1 NAME

Tapper::Cmd::Scenario - Backend functions for manipulation of scenario in the database

=head1 SYNOPSIS

This project offers backend functions for all projects for manipulation the
database on a higher level than that offered by Tapper::Schema.

    use Tapper::Cmd::Scenario;

    my $bar = Tapper::Cmd::Scenario->new();
    $bar->add($scenario);
    ...

=head1 FUNCTIONS

=head2 create

Create a new scenario from one element of a test plan (actually a test
plan instance). If the new scenario belong to a test plan instance the
function expects the id of this instance as second parameter.

@param hash ref - test plan element
@param instance - test plan instance id

@return array   - scenario ids

=cut

sub create {
        my ($self, $scenario, $instance) = @_;
        $scenario->{instance_id} ||= $instance;
        return $self->add($scenario);
}

=head2 parse_interdep

Parse an interdep scenario and do everything needed to put it into the
database.

@param hash ref - config containing all relevant information
@param hash ref - options

@return success - 0
@return error   - die with error text

=cut

sub parse_interdep
{
        my ($self, $conf) = @_;

        # TODO
        # 1.) make atomic
        # 2.) check whether more than 2 testruns are local and prevent sync in this case

        my $scenario = model('TestrunDB')->resultset('Scenario')->new({type => 'interdep',
                                                                       options => $conf->{scenario_options} || $conf->{options},
                                                                       name => $conf->{scenario_name} || $conf->{name},
                                                                      });
        $scenario->insert;
        my $sc_id    = $scenario->id;
        my @all_ids;
        foreach my $plan (@{$conf->{scenario_description} || $conf->{description}}) {
                my $tr = Tapper::Cmd::Testrun->new();
                $plan->{scenario_id} ||= $sc_id;
                $plan->{status} = 'prepare';
                my @ids = $tr->create($plan, $conf->{instance_id});
                push @all_ids, @ids;
        }

        # when there is only on scenario element in the DB and the scheduler
        # picks it it will think all scenario elements are fitted and start it
        # therefore, we can only set them to 'schedule' when all testruns are in the DB
        foreach my $id (@all_ids) {
                my $testrun = model('TestrunDB')->resultset('Testrun')->find($id);
                $testrun->testrun_scheduling->status('schedule');
                $testrun->testrun_scheduling->update
        }

        return $sc_id;
}


=head2 add

Add a new scenario to database. Add with testplan instance id if given.

@param hash ref - options for new scenario
@param instance - test plan instance id

@return success - scenario id
@return error   - undef

=cut

sub add {
        my ($self, $scenario) = @_;


        given ($scenario->{scenario_type}) {
                when ('interdep') {
                        return $self->parse_interdep($scenario);
                }
                default {
                        die "Unknown scenario type ", $scenario->{scenario_type};
                }
        }
}



=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=cut

sub del {
        my ($self, $id) = @_;
        my $scenario = model('TestrunDB')->resultset('Scenario')->find($id);
        $scenario->delete();
        return 0;
}

1; # End of Tapper::Cmd::Testrun

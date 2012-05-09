package Tapper::Cmd;
# ABSTRACT: Tapper - Backend functions for CLI and Web

use Moose;

use Tapper::Model 'model';

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module is the base module that
contains common functions of all modules in the project. No such functions
exist yet.

    use Tapper::Cmd::Testrun;
    use Tapper::Cmd::Precondition;

    my $foo = Tapper::Cmd::Precondition->new();
    $foo->add($precondition);

    my $bar = Tapper::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=cut

=head1 FUNCTIONS

=head2 assign_preconditions

Assign a list of preconditions to a testrun. Both have to be given as valid
ids.

@param int - testrun id
@param array of int - precondition ids

@return success - 0
@return error   - error string

=cut

sub assign_preconditions
{
        my ($self, $testrun_id, @preconditions) = @_;
        my $testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
        return $testrun->assign_preconditions(@preconditions);

}

1; # End of Tapper::Cmd

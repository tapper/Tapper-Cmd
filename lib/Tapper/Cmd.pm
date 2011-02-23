package Tapper::Cmd;

=head1 NAME

Tapper::Cmd - Backend functions for manipluation of testruns and preconditions in the database

=cut
use Moose;

use Tapper::Model 'model';

our $VERSION = '2.010035';


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

=head1 FUNCTIONS

=cut 



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


=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<osrc-sysin at elbe.amd.com>, or through
the web interface at L<https://osrc/bugs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2009 OSRC SysInt Team, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Tapper::Cmd

use MooseX::Declare;

=head1 NAME

Artemis::Cmd - Backend functions for manipluation of testruns and preconditions in the database

=head1 VERSION

Version 0.01

=cut

{
        # just for CPAN
        package Artemis::Cmd;
        our $VERSION = '2.010026';
}


=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module is the base module that
contains common functions of all modules in the project. No such functions
exist yet.

    use Artemis::Cmd::Testrun;
    use Artemis::Cmd::Precondition;

    my $foo = Artemis::Cmd::Precondition->new();
    $foo->add($precondition);

    my $bar = Artemis::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS

=cut 

class Artemis::Cmd { 
        use Artemis::Model 'model';


=head2

Assign a list of preconditions to a testrun. Both have to be given as valid
ids.

@param int - testrun id
@param array of int - precondition ids

@return success - 0
@return error   - error string

=cut

        method assign_preconditions($testrun_id, @preconditions)
        {
                my $testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
                return $testrun->assign_preconditions(@preconditions);

        }
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

1; # End of Artemis::Cmd

package Artemis::Cmd::Precondition;

use MooseX::Declare;

=head1 NAME

Artemis::Cmd::Precondition - Backend functions for manipluation of preconditions in the database

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module handles the precondition part.

    use Artemis::Cmd::Testrun;

    my $bar = Artemis::Cmd::Precondition->new();
    $bar->add($precondition);
    ...

=head1 FUNCTIONS

=cut

class Artemis::Cmd::Precondition extends Artemis::Cmd {
        use Artemis::Model 'model';
        # use Artemis::Exception::Param;
        # use YAML::Syck;


=head2 add

Add a new precondition. Expects a precondition in YAML format. Multiple
preconditions may be given as one string. In this case every valid
precondition (i.e. those with a precondition_type) will be added. This is
useful for macro preconditions.


@param string - preconditions in YAML format.

@return success - list of precondition ids
@return error   - undef

@throws Artemis::Exception::Param

=cut


        method add($yaml)
        {
                return model('TestrunDB')->resultset('Precondition')->add($yaml);
        }

=head2 update

Update a given precondition.

@param int    - precondition id
@param string - precondition as it should be

@return success - precondition id
@return error   - error string

@throws Artemis::Exception::Param


=cut

        method update($id, $condition)
        {
                my $precondition = model('TestrunDB')->resultset('Precondition')->find($id);
                die Artemis::Exception::Param->new("Precondition with id $id not found") if not $precondition;

                return $precondition->update_content($condition);
        }


=head2 del

Delete a precondition with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - precondition id

@return success - 0
@return error   - error string

=cut

        method del($id)
        {
                my $precondition = model('TestrunDB')->resultset('Precondition')->find($id);
                return qq(No precondition with id "$id" found) if not $precondition;;
                $precondition->delete();
                return 0;
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

1; # End of Artemis::Cmd::Testrun

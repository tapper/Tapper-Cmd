use MooseX::Declare;

=head1 NAME

Artemis::Cmd::Scenario - Backend functions for manipulation of scenario in the database

=head1 SYNOPSIS

This project offers backend functions for all projects for manipulation the
database on a higher level than that offered by Artemis::Schema.

    use Artemis::Cmd::Scenario;

    my $bar = Artemis::Cmd::Scenario->new();
    $bar->add($scenario);
    ...

=head1 FUNCTIONS


=head2 add

Add a new scenario to database.

=cut

class Artemis::Cmd::Scenario
    extends Artemis::Cmd
{
        use Artemis::Model 'model';
        use Artemis::Exception;

=head2 add

Add a new scenario to database

@param hash ref - options for new scenario

@return success - scenario id
@return error   - undef

=cut

        method add($args) {

                my %args = %{$args}; # copy
                my $scenario = model('TestrunDB')->resultset('Scenario')->new(\%args);
                $scenario->insert;
                return $scenario->id;
        }
        


=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=cut

        method del($id) {
                my $scenario = model('TestrunDB')->resultset('Scenario')->find($id);
                $scenario->delete();
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

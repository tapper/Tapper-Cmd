use MooseX::Declare;

=head1 NAME

Artemis::Cmd::Queue - Backend functions for manipluation of queues in the database

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
queues in the database. This module handles the testrun part.

    use Artemis::Cmd::Queue;

    my $bar = Artemis::Cmd::Queue->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS

=head2 add

Add a new queue to database.

=cut

class Artemis::Cmd::Queue
    extends Artemis::Cmd
{
        use Artemis::Model 'model';
        use DateTime;

=head2 add

Add a new queue.
-- required --
* name - string
* priority - int

@param hash ref - options for new testrun

@return success - testrun id
@return error   - undef

=cut

        method add($args) {

                my %args = %{$args}; # copy

                my $q = model('TestrunDB')->resultset('Queue')->new(\%args);
                $q->insert;
                return $q->id;
        }


=head2 update

Changes values of an existing testrun. Hostname/hardwaredb_systems_id and
owner/owner_user_id allow to specify the associated value as id or string
which will be converted to the associated id. If both values are given the id
is used and the string is ignored. The function expects a hash reference with
the following options (at least one should be given):

* hardwaredb_systems_id - int
or
* hostname  - string
* notes     - string
* shortname - string
* topic     - string
* date      - DateTime
* owner_user_id - int
or
* owner     - string

@param int      - testrun id
@param hash ref - options for new testrun

@return success - testrun id
@return error   - undef

=cut

        method update($id, $args) {
                my %args = %{$args}; # copy

                my $testrun = model('TestrunDB')->resultset('Testrun')->find($id);

                $args{hardwaredb_systems_id} = $args{hardwaredb_systems_id} || Artemis::Model::get_systems_id_for_hostname( $args{hostname} ) if $args{hostname};
                $args{owner_user_id}         = $args{owner_user_id}         || Artemis::Model::get_user_id_for_login( $args{owner} )          if $args{owner};

                return $testrun->update_content(\%args);
        }

=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=cut

        method del($id) {
                my $testrun = model('TestrunDB')->resultset('Testrun')->find($id);
                $testrun->delete();
                return 0;
        }

=head2 rerun

Insert a new testrun into the database. All values not given are taken from
the existing testrun given as first argument.

@param int      - id of original testrun
@param hash ref - different values for new testrun

@return success - testrun id
@return error   - error string

=cut

        method rerun($id, $args?) {
                my %args = %{$args || {}}; # copy

                my $testrun = model('TestrunDB')->resultset('Testrun')->find( $id );

                $args{owner_user_id}         = $args{owner_user_id}         || $args{owner}    ? Artemis::Model::get_user_id_for_login(       $args{owner}    ) : undef;
                $args{hardwaredb_systems_id} = $args{hardwaredb_systems_id} || $args{hostname} ? Artemis::Model::get_systems_id_for_hostname( $args{hostname} ) : undef;

                return $testrun->rerun(\%args);
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

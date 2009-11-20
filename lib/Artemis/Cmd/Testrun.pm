use MooseX::Declare;

=head1 NAME

Artemis::Cmd::Testrun - Backend functions for manipluation of testruns in the database

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module handles the testrun part.

    use Artemis::Cmd::Testrun;

    my $bar = Artemis::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS


=head2 add

Add a new testrun to database.

=cut

class Artemis::Cmd::Testrun
    extends Artemis::Cmd
{
        use Artemis::Model 'model';
        use DateTime;
        use Data::Dumper;
        use Artemis::Exception;

=head2 add

Add a new testrun. Owner/owner_user_id and requested_hosts/requested_host_ids
allow to specify the associated value as id or string which will be converted
to the associated id. If both values are given the id is used and the string
is ignored. The function expects a hash reference with the following options:
-- optional --
* requested_host_ids - array of int
or
* requested_hosts    - array of string

* notes - string
* shortname - string
* topic - string
* date - DateTime

* owner_user_id - int
or
* owner - string

@param hash ref - options for new testrun

@return success - testrun id
@return error   - undef

=cut

        method add($args) {

                my %args = %{$args}; # copy

                $args{notes}                 ||= '';
                $args{shortname}             ||=  '';

                $args{topic_name}              = $args->{topic}    || 'Misc';
                my $topic = model('TestrunDB')->resultset('Topic')->find_or_create({name => $args{topic_name}});
                
                $args{earliest}              ||= DateTime->now;
                $args{owner}                 ||= $ENV{USER};
                $args{owner_user_id}         ||= Artemis::Model::get_user_id_for_login(       $args->{owner}    );
                
                
                if (not $args{queue_id}) {
                        $args{queue}   ||= 'AdHoc';
                        my $queue_result = model('TestrunDB')->resultset('Queue')->search({name => $args{queue}}); 
                        return if not $queue_result->count;
                        $args{queue_id}  = $queue_result->first->id;
                }
                return model('TestrunDB')->resultset('Testrun')->add(\%args);
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

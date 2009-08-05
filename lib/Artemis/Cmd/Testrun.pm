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

class Artemis::Cmd::Testrun extends Artemis::Cmd {
        use Artemis::Model 'model';
        use DateTime;

=head2 add

Add a new testrun. It expects a has reference with the following options:
-- required --
* hostname - string
-- optional --
* notes - string
* shortname - string
* topic - string
* date - DateTime
* owner - string

@param hash ref - options for new testrun

@return success - testrun id
@return error   - undef

=cut

        method add($args)
        {

                my $notes        = $args->{notes}        || '';
                my $shortname    = $args->{shortname}    || '';
                my $topic_name   = $args->{topic}        || 'Misc';
                my $date         = $args->{earliest}     || DateTime->now;
                my $hostname     = $args->{hostname};
                my $owner        = $args->{owner}        || $ENV{USER};

                my $hardwaredb_systems_id = $self->_get_systems_id_for_hostname( $hostname );
                my $owner_user_id         = $self->_get_user_id_for_login( $owner );

                my $testrun = model('TestrunDB')->resultset('Testrun')->new
                  ({
                    notes                 => $notes,
                    shortname             => $shortname,
                    topic_name            => $topic_name,
                    starttime_earliest    => $date,
                    owner_user_id         => $owner_user_id,
                    hardwaredb_systems_id => $hardwaredb_systems_id,
                   });
                $testrun->insert;
                return $testrun->id;
        }


=head2 update

Changes values of an existing testrun. It expects a has reference with the
following options (at least one should be given):
* hostname  - string
* notes     - string
* shortname - string
* topic     - string
* date      - DateTime
* owner     - string

@param int      - testrun id
@param hash ref - options for new testrun

@return success - testrun id
@return error   - undef

=cut

        method update($id, $args)
        {
                my $testrun = model('TestrunDB')->resultset('Testrun')->find($id);

                $args->{hardwaredb_systems_id} = $self->_get_systems_id_for_hostname( $args->{hostname} ) if $args->{hostname};
                $args->{owner_user_id}         = $self->_get_user_id_for_login( $args->{owner} ) if $args->{owner};

                $testrun->notes                 ( $args->{notes}                 ) if $args->{notes};
                $testrun->shortname             ( $args->{shortname}             ) if $args->{shortname};
                $testrun->topic_name            ( $args->{topic}                 ) if $args->{topic};
                $testrun->starttime_earliest    ( $args->{date}                  ) if $args->{date};
                $testrun->owner_user_id         ( $args->{owner_user_id}         ) if $args->{owner_user_id};
                $testrun->hardwaredb_systems_id ( $args->{hardwaredb_systems_id} ) if $args->{hardwaredb_systems_id};
                $testrun->update;
                return $testrun->id;
        }

=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=cut

        method del($id)
        {
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

        method rerun($id, $args?)
        {
                my $testrun               = model('TestrunDB')->resultset('Testrun')->find( $id );
                my $owner_user_id         = Artemis::CLI::Testrun::_get_user_id_for_login(       $args->{owner}    ) if $args->{owner};
                my $hardwaredb_systems_id = Artemis::CLI::Testrun::_get_systems_id_for_hostname( $args->{hostname} ) if $args->{hostname};
                my $testrun_new           = model('TestrunDB')->resultset('Testrun')->new
                  ({
                    notes                 => $args->{notes}         || $testrun->notes,
                    shortname             => $args->{shortname}     || $testrun->shortname,
                    topic_name            => $args->{topic_name}    || $testrun->topic_name,
                    starttime_earliest    => $args->{earliest}      || DateTime->now,
                    test_program          => '',
                    owner_user_id         => $owner_user_id         || $testrun->owner_user_id,
                    hardwaredb_systems_id => $hardwaredb_systems_id || $testrun->hardwaredb_systems_id,
                   });

                $testrun_new->insert;

                my $preconditions = $testrun->preconditions->search({}, {order_by => 'succession'});
                my @preconditions;
                while (my $precond = $preconditions->next) {
                        push @preconditions, $precond->id;
                }
                $self->assign_preconditions($testrun_new->id, @preconditions);
                return $testrun_new->id;
        }

        method _get_systems_id_for_hostname($name)
        {
                return model('HardwareDB')->resultset('Systems')->search({systemname => $name, active => 1})->first->lid
        }

        method _get_user_id_for_login($login)
        {

                my $user = model('TestrunDB')->resultset('User')->search({ login => $login })->first;
                my $user_id = $user ? $user->id : 0;
                return $user_id;
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

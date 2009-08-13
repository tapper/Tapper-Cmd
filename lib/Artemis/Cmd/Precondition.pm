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
        use Artemis::Exception::Param;
        use YAML::Syck;


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
                $yaml .= "\n" unless $yaml =~ /\n$/;
                my $yaml_error = $self->_yaml_ok($yaml);
                die Artemis::Exception::Param->new($yaml_error) if $yaml_error;



                my @precond_list = Load($yaml);
                my @precond_ids;

                foreach my $precond_data (@precond_list) {
                        # (XXX) decide how to handle empty preconditions
                        next if not (ref($precond_data) eq 'HASH');
                        my $shortname    = $precond_data->{shortname} || '';
                        my $timeout      = $precond_data->{timeout};
                        my $precondition = model('TestrunDB')->resultset('Precondition')->new
                          ({
                            shortname    => $shortname,
                            precondition => Dump($precond_data),
                            timeout      => $timeout,
                           });
                        $precondition->insert;
                        push @precond_ids, $precondition->id;
                }
                return @precond_ids;
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
                my $yaml_error = $self->_yaml_ok($condition);
                die Artemis::Exception::Param->new($yaml_error) if $yaml_error;

                my $precondition = model('TestrunDB')->resultset('Precondition')->find($id);
                die Artemis::Exception::Param->new("Precondition with id $id not found") if not $precondition;

                my $cond_hash = Load($condition);

                $precondition->shortname( $cond_hash->{shortname} ) if $cond_hash->{shortname};
                $precondition->precondition( $condition );
                $precondition->timeout( $cond_hash->{timeout} ) if $cond_hash->{timeout};
                $precondition->update;


                return $precondition->id;
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
                $precondition->delete();
                return 0;
        }


=head2 _yaml_ok

Check whether given string is valid yaml.

@param string - yaml

@return success - undef
@return error   - error string

=cut

        method _yaml_ok($condition)
        {
                my @res;
                eval {
                        @res = Load($condition);
                };
                return $@;
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

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

@param hash ref - options for new queue

@return success - queue id
@return error   - undef

=cut

        method add($args) {

                my %args = %{$args}; # copy

                my $q = model('TestrunDB')->resultset('Queue')->new(\%args);
                $q->insert;
                my $all_queues = model('TestrunDB')->resultset('Queue');
                foreach my $queue ($all_queues->all) {
                        $queue->runcount($queue->priority);
                        $queue->update;
                }
                return $q->id;
        }


=head2 update

Changes values of an existing queue. 

@param int      - queue id
@param hash ref - overwrite these options

@return success - queue id
@return error   - undef

=cut

        method update($id, $args) {
                my %args = %{$args}; # copy

                my $queue = model('TestrunDB')->resultset('Queue')->find($id);
                
                return $queue->update_content(\%args);
        }

=head2 del

Delete a queue with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - queue id

@return success - 0
@return error   - error string

=cut

        method del($id) {
                my $testrun = model('TestrunDB')->resultset('Queue')->find($id);
                $testrun->delete();
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

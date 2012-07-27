package Tapper::Cmd::Queue;
use Moose;

use DateTime;

use Tapper::Model 'model';

extends 'Tapper::Cmd';


=head1 NAME

Tapper::Cmd::Queue - Backend functions for manipluation of queues in the database

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
queues in the database. This module handles the testrun part.

    use Tapper::Cmd::Queue;

    my $bar = Tapper::Cmd::Queue->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS

=head2 add

Add a new queue to database.

=cut


=head2 add

Add a new queue.
-- required --
* name - string
* priority - int

@param hash ref - options for new queue

@return success - queue id
@return error   - undef

=cut

sub add {
        my ($self, $args) = @_;
        my %args = %{$args};    # copy

        $args{is_deleted} = 0;
        
        my $q = model('TestrunDB')->resultset('Queue')->update_or_create(\%args);
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

sub update {
        my ($self, $id, $args) = @_;
        my %args = %{$args};    # copy

        my $queue = model('TestrunDB')->resultset('Queue')->find($id);
        my $retval = $queue->update_content(\%args);

        my $all_queues = model('TestrunDB')->resultset('Queue');
        foreach my $queue ($all_queues->all) {
                $queue->runcount($queue->priority);
                $queue->update;
        }

        return $retval;
}

=head2 del

Delete a queue with given id. Its named del instead of delete to prevent
confusion with the buildin delete function. If the queue is not empty
and force is not given, we keep the queue and only set it to deleted to
not break showing old testruns and their results.

@param int  - queue id
@param bool - force deleted

@return success - 0
@return error   - error string

=cut

sub del {
        my ($self, $id, $force) = @_;
        my $queue = model('TestrunDB')->resultset('Queue')->find($id);
        $queue->is_deleted(1);
        $queue->active(0);
        $queue->update;
        my $attached_jobs = $queue->testrunschedulings->search({status => 'schedule'});
        while (my $job = $attached_jobs->next) {
                $job->status('finished');
                $job->update;
        } 

        # empty queues can be deleted, because it does not break anything
        $queue->delete if $queue->testrunschedulings->count == 0;

        return 0;
}

1; # End of Tapper::Cmd::Testrun

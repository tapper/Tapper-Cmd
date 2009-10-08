#!perl

use strict;
use warnings;

use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use TryCatch;
use Test::More;

use Artemis::Cmd::Queue;
use Artemis::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $queue = Artemis::Cmd::Queue->new();
isa_ok($queue, 'Artemis::Cmd::Queue', '$queue');

my $retval   = $queue->add({name => 'newqueue', priority => 100});
my $queue_rs = model('TestrunDB')->resultset('Queue')->find($retval);
isa_ok($queue, 'Artemis::Cmd::Queue', 'Insert queue / queue id returned');

$queue_rs = model('TestrunDB')->resultset('Queue');
foreach my $queue_r ($queue_rs->all) {
        is($queue_r->runcount, $queue_r->priority, 'Insert queue / runcount');
}

done_testing();


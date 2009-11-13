#!perl

use strict;
use warnings;

use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use TryCatch;
use Test::More;

use Artemis::Cmd::Scenario;
use Artemis::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $scen = Artemis::Cmd::Scenario->new();
isa_ok($scen, 'Artemis::Cmd::Scenario', '$scenario');

my $retval  = $scen->add({type => 'interdep'});
my $scen_rs = model('TestrunDB')->resultset('Scenario')->find($retval);
isa_ok($scen_rs, 'Artemis::Schema::TestrunDB::Result::Scenario', 'Insert scenario / scenario id returned');

$retval  = $scen->del($scen_rs->id);
is($retval, 0, 'Delete scenario');
$scen_rs = model('TestrunDB')->resultset('Scenario')->find($scen_rs->id);

done_testing();


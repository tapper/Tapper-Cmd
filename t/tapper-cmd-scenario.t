#!perl

use strict;
use warnings;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use Test::More;

use Tapper::Cmd::Scenario;
use Tapper::Model 'model';
use YAML::XS;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $scen = Tapper::Cmd::Scenario->new();
isa_ok($scen, 'Tapper::Cmd::Scenario', '$scenario');

my $scenario = do {local $/;
                   open (my $fh, '<', 't/misc_files/scenario.sc') or die "Can open file:$!\n";
                   <$fh>
           };

my @retval  = $scen->add(YAML::XS::Load($scenario));
my $scen_rs = model('TestrunDB')->resultset('Scenario')->find($retval[0]);
isa_ok($scen_rs, 'Tapper::Schema::TestrunDB::Result::Scenario', 'Insert scenario / scenario id returned');

my $retval  = $scen->del($scen_rs->id);
is($retval, 0, 'Delete scenario');
$scen_rs = model('TestrunDB')->resultset('Scenario')->find($scen_rs->id);

$scenario = do {local $/;
                   open (my $fh, '<', 't/misc_files/single.sc') or die "Can open file 'single.sc':$!\n";
                   <$fh>
           };

@retval  = $scen->add(YAML::XS::Load($scenario));
my $testrun_res = model('TestrunDB')->resultset('Scenario')->find($retval[0]);
isa_ok($testrun_res, 'Tapper::Schema::TestrunDB::Result::Scenario', 'Insert single scenario / testrun id returned');

done_testing();


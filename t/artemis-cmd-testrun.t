#!perl

use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use Test::More tests => 5;
use Artemis::Cmd::Testrun;
use Artemis::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $cmd = Artemis::Cmd::Testrun->new();
isa_ok($cmd, 'Artemis::Cmd::Testrun', '$testrun');

my $hardwaredb_systems_id = $cmd->_get_systems_id_for_hostname('bascha');
is($hardwaredb_systems_id, 15, 'get system id for hostname');

my $user_id = $cmd->_get_user_id_for_login('sschwigo');
is($user_id, 12, 'get user id for login');

my $testrun_args = {hostname  => 'bascha',
                    notes     => 'foo',
                    shortname => 'foo',
                    topic     => 'foo',
                    earliest  => DateTime->new( year   => 1964,
                                                month  => 10,
                                                day    => 16,
                                                hour   => 16,
                                                minute => 12,
                                                second => 47),
                    owner      => 'sschwigo'};

my $testrun_id = $cmd->add($testrun_args);
ok(defined($testrun_id), 'Adding testrun');
my $testrun = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id})->first;
my $retval = {hostname    => $testrun->hardwaredb_systems_id,
              owner       => $testrun->owner_user_id,
              notes       => $testrun->notes,
              shortname   => $testrun->shortname,
              topic       => $testrun->topic_name,
              earliest    => $testrun->starttime_earliest,
             };
$testrun_args->{hostname} =  15;
$testrun_args->{owner}    =  12;
is_deeply($retval, $testrun_args, 'Values of added test run');

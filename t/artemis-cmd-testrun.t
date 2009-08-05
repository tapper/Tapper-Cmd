#!perl

use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use warnings;
use strict;

use Test::More tests => 11;
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


#######################################################
#
#   check support methods
#
#######################################################

my $hardwaredb_systems_id = $cmd->_get_systems_id_for_hostname('bascha');
is($hardwaredb_systems_id, 15, 'get system id for hostname');

my $user_id = $cmd->_get_user_id_for_login('sschwigo');
is($user_id, 12, 'get user id for login');


#######################################################
#
#   check add method
#
#######################################################

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


#######################################################
#
#   check update method
#
#######################################################

my $testrun_id_new = $cmd->update($testrun_id, {hostname => 'iring'});
is($testrun_id_new, $testrun_id, 'Updated testrun without creating a new one');

$testrun_args->{hostname} = 12;
$testrun = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id})->first;
$retval = {hostname    => $testrun->hardwaredb_systems_id,
           owner       => $testrun->owner_user_id,
           notes       => $testrun->notes,
           shortname   => $testrun->shortname,
           topic       => $testrun->topic_name,
           earliest    => $testrun->starttime_earliest,
          };
is_deeply($retval, $testrun_args, 'Values of updated test run');


#######################################################
#
#   check rerun method
#
#######################################################

$testrun_id_new = $cmd->rerun($testrun_id);
isnt($testrun_id_new, $testrun_id, 'Rerun testrun with new id');

$testrun        = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
my $testrun_new = model('TestrunDB')->resultset('Testrun')->find($testrun_id_new);

$retval = {hostname    => $testrun->hardwaredb_systems_id,
           owner       => $testrun->owner_user_id,
           notes       => $testrun->notes,
           shortname   => $testrun->shortname,
           topic       => $testrun->topic_name,
          };
$testrun_args = {hostname    => $testrun_new->hardwaredb_systems_id,
                 owner       => $testrun_new->owner_user_id,
                 notes       => $testrun_new->notes,
                 shortname   => $testrun_new->shortname,
                 topic       => $testrun_new->topic_name,
          };


is_deeply($retval, $testrun_args, 'Values of rerun test run');


#######################################################
#
#   check del method
#
#######################################################

$retval = $cmd->del($testrun_id);
is($retval, 0, 'Delete testrun');
$testrun = model('TestrunDB')->resultset('Precondition')->find($testrun_id);
is($testrun, undef, 'Delete correct testrun');

#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Artemis::Cmd::Testrun;
use Artemis::Cmd::Testrun::Command::list;
use Artemis::Cmd::Testrun::Command::new;
use Artemis::Cmd::Testrun::Command::newprecondition;
use Artemis::Cmd::Testrun::Command::listprecondition;
use Artemis::Schema::TestTools;
use Artemis::Model 'model';
use Test::Fixture::DBIC::Schema;

plan tests => 20;

# --------------------------------------------------

my $OK_YAML = '
---
file_order:
  - t/00-artemis-meta.t
  - t/00-load.t
  - t/artemis_logging_netlogappender.t
  - t/artemis_mcp_builder.t
  - t/artemis_mcp_runtest.t
  - t/artemis_model.t
  - t/artemis_systeminstaller.t
  - t/artemis.t
  - t/boilerplate.t
  - t/experiments.t
start_time: 1213352566
stop_time: 1213352568
';

my $ERR_YAML = '
---
file_order:
  - t/experiments.t
start_time: 1213352566
  stop_time: 1213352568
';

is(Artemis::Cmd::Testrun::Command::newprecondition::yaml_ok($OK_YAML), 1, "ok_yaml with correct yaml");
is(Artemis::Cmd::Testrun::Command::newprecondition::yaml_ok($ERR_YAML), 0, "ok_yaml with error yaml");

# --------------------------------------------------


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $testrun = Artemis::Cmd::Testrun::Command::list::_get_entry_by_id (23); # perfmon

is($testrun->id, 23, "testrun id");
is($testrun->notes, 'perfmon', "testrun notes");
is($testrun->shortname, 'perfmon', "testrun shortname");
is($testrun->topic_name, 'Software', "testrun topic_name");
is($testrun->topic->name, 'Software', "testrun topic->name");
is($testrun->topic->description, 'any non-kernel software, e.g., libraries, programs', "testrun topic->description");
is($testrun->test_program, '/usr/local/share/artemis/testsuites/perfmon/t/do_test.sh', "testrun test_program");

is(Artemis::Cmd::Testrun::_get_user_for_login('sschwigo')->id, 12, "_get_user_for_login");

# --------------------------------------------------

# TODO: {
#         local $TODO = 'do not forget to implement some subs';

#         isnt(Artemis::Cmd::Testrun::_get_systems_id_for_hostname("affe"), 42, "_get_systems_id_for_hostname");
# }

my $precond_id = `/usr/bin/env perl -Ilib bin/artemis-testrun newprecondition --shortname="perl-5.10" --condition="affe:"`;
chomp $precond_id;

my $precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
ok($precond->id, 'inserted precond / id');
is($precond->shortname, 'perl-5.10', 'inserted precond / shortname');
is($precond->precondition, 'affe:', 'inserted precond / yaml');

# --------------------------------------------------

my $testrun_id = `/usr/bin/env perl -Ilib bin/artemis-testrun new --topic=Software --test_program=/usr/local/share/artemis/testsuites/perfmon/t/do_test.sh --hostname=iring`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
ok($testrun->id, 'inserted testrun / id');
is($testrun->test_program, '/usr/local/share/artemis/testsuites/perfmon/t/do_test.sh', 'inserted testrun / test_program');
is($testrun->hardwaredb_systems_id, 12, 'inserted testrun / systems_id');

# --------------------------------------------------

my $old_testrun_id = $testrun_id;
$testrun_id = `/usr/bin/env perl -Ilib bin/artemis-testrun update --id=$old_testrun_id --topic=Hardware --test_program=/tmp/yet/another/test.sh --hostname=iring`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
is($testrun->id, $old_testrun_id, 'updated testrun / id');
is($testrun->topic_name, "Hardware", 'updated testrun / topic');
is($testrun->test_program, '/tmp/yet/another/test.sh', 'updated testrun / test_program');
is($testrun->hardwaredb_systems_id, 12, 'updated testrun / systems_id');


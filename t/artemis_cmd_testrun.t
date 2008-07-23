#! /usr/bin/env perl

use strict;
use warnings;

use t::Tools;
use Test::Fixture::DBIC::Schema;
use Artemis::Cmd::Testrun;
use Artemis::Cmd::Testrun::Command::list;
use Artemis::Cmd::Testrun::Command::new;
use Test::More tests => 10;

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


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
#construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $testrun = Artemis::Cmd::Testrun::Command::list::_get_testrun_by_id (23); # perfmon

is($testrun->id, 23, "testrun id");
is($testrun->notes, 'perfmon', "testrun notes");
is($testrun->shortname, 'perfmon', "testrun shortname");
is($testrun->topic_name, 'Software', "testrun topic_name");
is($testrun->topic->name, 'Software', "testrun topic->name");
is($testrun->topic->description, 'any non-kernel software, e.g., libraries, programs', "testrun topic->description");
is($testrun->test_program, '/usr/local/share/artemis/testsuites/perfmon/t/do_test.sh', "testrun test_program");

is(Artemis::Cmd::Testrun::_get_user_for_login('sschwigo')->id, 12, "_get_user_for_login");

# TODO: {
#         local $TODO = 'do not forget to implement some subs';

#         isnt(Artemis::Cmd::Testrun::_get_systems_id_for_hostname("affe"), 42, "_get_systems_id_for_hostname");
# }

system q{/usr/bin/env perl -Ilib bin/artemis-testrun newprecondition --shortname="perl-5.10" --condition="affe:"};
system q{/usr/bin/env perl -V};

is(Artemis::Cmd::Testrun::Command::newprecondition::yaml_ok($OK_YAML), "ok_yaml with correct yaml");
isnt(Artemis::Cmd::Testrun::Command::newprecondition::yaml_ok($ERR_YAML), "ok_yaml with error yaml");

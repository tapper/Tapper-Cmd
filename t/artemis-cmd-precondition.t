#!perl

use strict;
use warnings;

use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use TryCatch;
use Test::More tests => 3;

use Artemis::Cmd::Precondition;
use Artemis::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $precondition = Artemis::Cmd::Precondition->new();
isa_ok($precondition, 'Artemis::Cmd::Precondition', '$precondition');


my $yaml = q(# artemis-mandatory-fields: kernel_version
---
precondition_type: package
filename: linux-2.6.18
---
precondition_type: exec
filename: /bin/gen_initrd.sh
options:
  - 2.6.18
---
);

my @precond_ids = $precondition->add($yaml);

is(1, $#precond_ids,  'Adding multiple preconditions');

$precondition->assign_preconditions(23, @precond_ids);
my $testrun = model('TestrunDB')->resultset('Testrun')->search({id => 23})->first;

my @precond_hashes;
foreach my $precondition ($testrun->ordered_preconditions) {
        push @precond_hashes, $precondition->precondition_as_hash;
}

is_deeply(\@precond_hashes, [{
                              'filename' => 'linux-2.6.18',
                              'precondition_type' => 'package'
                             },
                             {
                              'options' => [
                                            '2.6.18'
                                           ],
                              'filename' => '/bin/gen_initrd.sh',
                              'precondition_type' => 'exec'
                             }], 'Assigning preconditions to testrun');
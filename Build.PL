use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new
    (
     module_name         => 'Artemis::Cmd',
     license             => 'restrictive',
     dist_author         => 'OSRC SysInt Team <osrc-sysint@elbe.amd.com>',
     dist_version_from   => 'lib/Artemis/Cmd.pm',
     build_requires => {
                        'Test::More' => 0,
                        'Test::Fixture::DBIC::Schema' => 0,
                        'Artemis::Test'               => 0,
                       },
     requires => {
                  'perl'            => '5.010',
                  'parent'          => 0,
                  'App::Cmd'        => 0,
                  'File::Slurp'     => 0,
                  'Artemis::Model'  => 0,
                  'Artemis::Schema' => 0,
                  'Data::Dumper'    => 0,
                  'DateTime::Format::Natural'    => 0,
                 },
     add_to_cleanup      => [ 'Artemis-Cmd-*' ],
     create_makefile_pl => 'traditional',
    );

$builder->create_build_script();

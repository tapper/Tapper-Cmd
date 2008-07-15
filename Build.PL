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
                        'Artemis::Test'               => '2.010005',
                       },
     requires => {
                  'perl'                      => '5.010',
                  'parent'                    => 0,
                  'App::Cmd'                  => 0,
                  'File::Slurp'               => 0,
                  'Artemis::Model'            => '2.010003',
                  'Artemis::Schema'           => '2.010012',
                  'Data::Dumper'              => 0,
                  'DateTime::Format::Natural' => 0,
                  'YAML::Syck'                => 0,
                 },
     add_to_cleanup      => [ 'Artemis-Cmd-*' ],
    );

$builder->create_build_script();

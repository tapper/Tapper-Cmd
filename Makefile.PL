use strict;
use warnings;

use inc::Module::Install;

name     'Artemis-Cmd';
all_from 'lib/Artemis/Cmd.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'freebsd';

requires 'perl'                  => '5.010';
requires 'Artemis::Model'        => '2.010020';
requires 'Kwalify'               => 0;
requires 'MooseX::Declare'       => 0;
requires 'YAML::Syck'            => 0;

build_requires 'Test::More';

WriteAll;


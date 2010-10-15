use strict;
use warnings;

use inc::Module::Install;

name     'Artemis-Cmd';
all_from 'lib/Artemis/Cmd.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'freebsd';

requires 'perl'                  => '5.010';
requires 'Artemis::Model'        => '2.010016';
requires 'Kwalify'               => 0;

build_requires 'Test::More';
build_requires 'TryCatch'        => "1.003";

WriteAll;


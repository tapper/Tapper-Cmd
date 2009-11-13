use strict;
use warnings;

use inc::Module::Install;

name     'Artemis-Cmd';
all_from 'lib/Artemis/Cmd.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';

requires 'perl'                  => '5.010';
requires 'MooseX::Declare'       => '0.27';
requires 'Artemis::Model'        => '2.010016';

build_requires 'Test::More';


WriteAll;


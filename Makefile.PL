use strict;
use warnings;

use inc::Module::Install;

name     'Tapper-Cmd';
all_from 'lib/Tapper/Cmd.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'freebsd';

requires 'perl'                  => '5.010';
requires 'Tapper::Model'         => "3.000001";
requires 'Kwalify'               => 0;
requires 'MooseX::Declare'       => 0;
requires 'YAML::Syck'            => 0;

build_requires 'Test::More';

author_requires 'Module::Install::WriteAll';

WriteAll;


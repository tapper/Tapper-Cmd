use strict;
use warnings;

use inc::Module::Install;

name     'Artemis-Cmd';
all_from 'lib/Artemis/Cmd.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';

requires 'perl'                  => '5.010';
requires 'Artemis::Model'        => '2.010016';
requires 'Kwalify'               => 0;

build_requires 'Test::More';

postamble("

live:
\t./script/dist_upload_wotan.sh dist || exit 1
\tssh artemis\@bancroft sudo /opt/artemis/bin/cpan Artemis::Cmd || exit 1

devel: install

");


WriteAll;


use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Artemis::Cmd',
    AUTHOR              => 'OSRC SysInt Team <osrc-sysint@elbe.amd.com>',
    VERSION_FROM        => 'lib/Artemis/Cmd.pm',
    ABSTRACT_FROM       => 'lib/Artemis/Cmd.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Artemis-Cmd-*' },
);

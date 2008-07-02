package t::Tools;

# inspired by Test::Fixture::DBIC::Schema

use strict;
use warnings;

use Artemis::Schema::TestrunDB;
use Artemis::Schema::ReportsDB;
use Artemis::Schema::HardwareDB;

use Artemis::Config;


my $testrundb_schema;
my $reportsdb_schema;
my $hardwaredb_schema;

sub setup_testrundb {

        # explicitely prefix into {test} subhash of the config file,
        # to avoid painful mistakes with deploy

        my $dsn = Artemis::Config->subconfig->{test}{database}{TestrunDB}{dsn};

        my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
        unlink $tmpfname;

        $testrundb_schema = Artemis::Schema::TestrunDB->connect($dsn,
                                                                Artemis::Config->subconfig->{test}{database}{TestrunDB}{username},
                                                                Artemis::Config->subconfig->{test}{database}{TestrunDB}{password},
                                                                { ignore_version => 1 }
                                                               );
        $testrundb_schema->deploy({ add_drop_table => 1 });
        eval { $testrundb_schema->upgrade; }
        print STDERR $@ if $@;
}

sub setup_reportsdb {

        # explicitely prefix into {test} subhash of the config file,
        # to avoid painful mistakes with deploy

        my $dsn = Artemis::Config->subconfig->{test}{database}{ReportsDB}{dsn};

        my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
        unlink $tmpfname;

        $reportsdb_schema = Artemis::Schema::ReportsDB->connect($dsn,
                                                                Artemis::Config->subconfig->{test}{database}{ReportsDB}{username},
                                                                Artemis::Config->subconfig->{test}{database}{ReportsDB}{password},
                                                                { ignore_version => 1 }
                                                               );
        $reportsdb_schema->deploy({ add_drop_table => 1 });
        eval { $reportsdb_schema->upgrade };
        print STDERR $@ if $@;
}

sub setup_hardwaredb {

        # explicitely prefix into {test} subhash of the config file,
        # to avoid painful mistakes with deploy

        print STDERR "\n\n*** SETUP HARDWAREDB *** \n";

        my $dsn = Artemis::Config->subconfig->{test}{database}{HardwareDB}{dsn};

        my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
        unlink $tmpfname;

        $hardwaredb_schema = Artemis::Schema::HardwareDB->connect($dsn,
                                                                  Artemis::Config->subconfig->{test}{database}{HardwareDB}{username},
                                                                  Artemis::Config->subconfig->{test}{database}{HardwareDB}{password},
                                                                  { ignore_version => 1 }
                                                               );
        $hardwaredb_schema->deploy();
        # not versioned: eval { $hardwaredb_schema->upgrade; }
}

sub import {
        my $pkg = caller(0);
        no strict 'refs';       ## no critic.
        *{"$pkg\::testrundb_schema"}  = sub () { $testrundb_schema };
        *{"$pkg\::reportsdb_schema"}  = sub () { $reportsdb_schema };
        *{"$pkg\::hardwaredb_schema"} = sub () { $hardwaredb_schema };
}

setup_testrundb;
setup_reportsdb;
setup_hardwaredb;

1;

package Tapper::Cmd::Init;
# ABSTRACT: Tapper - Backend functions for initially setting up Tapper

use 5.010;
use strict;
use warnings;

use Moose;
use Tapper::Cmd::DbDeploy;
use Tapper::Config;
use Tapper::Model 'model';
use File::ShareDir 'module_file';
use File::Slurp 'slurp';
use DBI;

extends 'Tapper::Cmd';


=head1 SYNOPSIS

This module provides functions to initially set up Tapper in C<$HOME/.tapper/>.

    use Tapper::Cmd::Init;
    my $cmd = Tapper::Cmd::Init->new;
    $cmd->init($options);
    ...

=head1 METHODS

=head2 mint_file ($init_dir, $basename)

Create file taken from sharedir into user's ~/.tapper/,
inclusive rewriting values dedicated for the user.

=cut

sub mint_file {
        my ($init_dir, $basename) = @_;

        my $HOME = $ENV{HOME};
        my $USER = $ENV{USER} || 'nobody';

        my $file = "$init_dir/$basename";
        if (-e $file) {
                say "$file already exists - skipped";
        } else {
                my $content = slurp module_file('Tapper::Cmd::Init', $basename);
                $content =~ s/__HOME__/$HOME/g;
                $content =~ s/__USER__/$USER/g;
                open my $INITCFG, ">", $file or die "Can not create file $file.\n";
                print $INITCFG $content;
                close $INITCFG;
                say "Created $file";
        }
}

=head2 make_subdir($dir)

Create a subdirectory with some log output.

=cut

sub make_subdir {
        my ($dir) = @_;
        if (! -d $dir) {
                mkdir $dir or die "Can not create $dir\n";
                say "Created $dir/";
        }
}

=head2 init($defaults)

Initialize $HOME/.tapper/

=cut

sub init
{
        my ($self, $options) = @_;
        my $db = $options->{db};

        my $HOME = $ENV{HOME};
        die "No home directory found.\n" unless $HOME && -d $HOME;

        make_subdir my $init_dir = "$HOME/.tapper";
        make_subdir my $logs_dir = "$HOME/.tapper/logs";

        mint_file ($init_dir, "tapper.cfg");
        mint_file ($init_dir, "log4perl.cfg");

        Tapper::Config::_switch_context; # reload config

        foreach my $db (qw(TestrunDB ReportsDB)) {
                my $dsn = Tapper::Config->subconfig->{database}{$db}{dsn};
                my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($dsn)
                 or die "Can't parse DBI DSN '$dsn'";
                if ($driver eq "SQLite") {
                        my ($dbname) = $driver_dsn =~ /dbname=(.*)/;
                        if (! -e $dbname) {
                                my $cmd = Tapper::Cmd::DbDeploy->new;
                                $cmd->dbdeploy($db);
                        } else {
                                say "$dbname already exists - skipped";
                        }
                }
        }
}

1;

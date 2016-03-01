package Tapper::Cmd::Init;
# ABSTRACT: Tapper - Backend functions for initially setting up Tapper

use 5.010;
use strict;
use warnings;

use Moose;
use Tapper::Cmd::DbDeploy;
use Tapper::Config;
use Tapper::Model 'model';
use File::ShareDir 'module_file', 'module_dir';
use File::Copy::Recursive 'dircopy';
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
        my ($init_dir, $basename, $force) = @_;

        my $HOME = $ENV{HOME};
        my $USER = $ENV{USER} || 'nobody';

        my $file = "$init_dir/$basename";
        if (-e $file and !$force) {
                say "SKIP    $file - already exists";
        } else {
                my $content = slurp module_file('Tapper::Cmd::Init', $basename);
                $content =~ s/__HOME__/$HOME/g;
                $content =~ s/__USER__/$USER/g;

                # set write permissions when $force is set
                if (-e $file) {
                  open my $INITCFG, "<", $file or die "Can not read file $file.\n";
                  my $perm = (stat $INITCFG)[2] & 07777;
                  chmod ($perm|0600, $INITCFG);
                  close $INITCFG;
                }

                # actually patch file
                open my $INITCFG, ">", $file or die "Can not create file $file.\n";
                print $INITCFG $content;
                close $INITCFG;
                say "CREATED $file";
        }
}

=head2 copy_subdir ($init_dir, $dirname)

Create subdir taken from sharedir into user's ~/.tapper/.

=cut

sub copy_subdir {
        my ($init_dir, $dirname) = @_;

        my $dir = "$init_dir/$dirname";
        if (-d $dir) {
                say "SKIP    $dir/ - already exists";
        } else {
                dircopy(module_dir('Tapper::Cmd::Init')."/$dirname", $dir);
                say "CREATED $dir/";
        }
}

=head2 make_subdir($dir)

Create a subdirectory with some log output.

=cut

sub make_subdir {
        my ($dir) = @_;
        if (-d $dir) {
                say "SKIP    $dir/ - already exists";
        } else {
                mkdir $dir or die "Can not create $dir\n";
                say "CREATED $dir/";
        }
}

=head2 dbdeploy

Initialize database in $HOME/.tapper/

=cut

sub dbdeploy
{
        Tapper::Config::_switch_context; # reload config

        my $dsn = Tapper::Config->subconfig->{database}{TestrunDB}{dsn};
        my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($dsn)
         or die "Can't parse DBI DSN '$dsn'";
        if ($driver eq "SQLite") {
                my ($dbname) = $driver_dsn =~ /dbname=(.*)/;
                if (! -e $dbname) {
                        my $cmd = Tapper::Cmd::DbDeploy->new;
                        $cmd->dbdeploy('TestrunDB');
                } else {
                        say "SKIP    $dbname - already exists";
                }
        }
}

=head2 benchmarkdeploy

Initialize benchmarkanything database in $HOME/.tapper/

=cut

sub benchmarkdeploy
{
        Tapper::Config::_switch_context; # reload config

        my $HOME = $ENV{HOME};
        my $dsn = Tapper::Config->subconfig->{benchmarkanything}{storage}{backend}{sql}{dsn};
        my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($dsn)
         or die "Can't parse DBI DSN '$dsn'";
        $ENV{BENCHMARKANYTHING_CONFIGFILE} = "$HOME/.tapper/tapper.cfg";
        system ("benchmarkanything-storage createdb") and die "Could not initialize BenchmarkAnything subsystem";
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

        make_subdir my $init_dir     = "$HOME/.tapper";
        make_subdir my $run_dir      = "$HOME/.tapper/run";
        make_subdir my $log_dir      = "$HOME/.tapper/logs";
        make_subdir my $out_dir      = "$HOME/.tapper/output";
        make_subdir my $repo_dir     = "$HOME/.tapper/repository";
        make_subdir my $img_dir      = "$HOME/.tapper/repository/images";
        make_subdir my $pkg_dir      = "$HOME/.tapper/repository/packages";
        make_subdir my $prg_dir      = "$HOME/.tapper/testprogram";
        make_subdir my $producer_dir = "$HOME/.tapper/producers";
        make_subdir my $localdata_dir = "$HOME/.tapper/localdata";

        copy_subdir ($init_dir, "hello-world");

        mint_file ($init_dir, "tapper.cfg");
        mint_file ($init_dir, "log4perl.cfg");
        mint_file ($init_dir, "log4perl_webgui.cfg");
        mint_file ($init_dir, "tapper-mcp-messagereceiver.conf");

        # Allow more fine-grained updates for testplans,
        # as we expect the user to have his own stuff in there.
        make_subdir my $tplan_dir = "$HOME/.tapper/testplans";

        make_subdir "$tplan_dir/$_" foreach qw(topic
                                               topic/xen
                                               topic/xen/generic
                                               topic/any
                                               topic/any/generic
                                               topic/kernel
                                               topic/kernel/generic
                                               topic/helloworld
                                               include
                                             );
        mint_file ($init_dir, $_) foreach qw(testplans/topic/xen/generic/upload-xen-dmesg.sh
                                             testplans/topic/xen/generic/test
                                             testplans/topic/xen/generic/guest-template.svm
                                             testplans/topic/xen/generic/guest-start-template.sh
                                             testplans/topic/any/generic/local
                                             testplans/topic/kernel/generic/test
                                             testplans/topic/helloworld/example01
                                             testplans/topic/helloworld/example02
                                             testplans/topic/helloworld/example03-builder
                                             testplans/include/distrodetails
                                             testplans/include/defaults
                                             testplans/include/defaultbenchmarks
                                           );

        #  force __HOME__ replacement for BenchmarkAnything config file
        mint_file ($init_dir, $_, 1) foreach qw(hello-world/00-set-environment/local-tapper-env.inc);

        dbdeploy;
        benchmarkdeploy;
}

1;

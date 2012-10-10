package Tapper::Cmd::Cobbler;

use warnings;
use strict;

use Moose;
use Tapper::Model 'model';
use Tapper::Config;
use Net::OpenSSH;

use parent 'Tapper::Cmd';


=head1 NAME

Tapper::Cmd::Testrun - Backend functions for manipluation of the cobbler database

=head1 SYNOPSIS

This project offers backend functions for all Tapper projects. This
module offers access to Cobbler database manipulation.

    use Tapper::Cmd::Cobbler;

    my $bar = Tapper::Cmd::Cobbler->new();
    $bar->host_new($hostname);
    ...

=head1 METHODS

=cut

# get_mac_address
#
# Retrieve the mac address of a host from features available in DB.
#
# @param Tapper::Schema::TestrunDB::Result::Host - host object
#
# @return string - mac address

sub get_mac_address
{
        my ($self, $host) = @_;
        my ($retval) = map{$_->value} grep{ $_->entry eq 'mac_address'} $host->features->all;
        return $retval;
}

# cobbler_execute
#
# Execute a Cobbler command.
#
# @param string - command
#
# @return string - output of cobbler

sub cobbler_execute
{
        my ($self, @command) = @_;

        my $cfg     = Tapper::Config->subconfig;
        my $cobbler_host = $cfg->{cobbler}->{host};

        my $output;
        if ($cobbler_host) {
                my $user = $cfg->{cobbler}->{user};
                my $ssh = Net::OpenSSH->new("$user\@$cobbler_host");
                $ssh->error and die "ssh  $user\@$cobbler_host failed: ".$ssh->error;
                $output = $ssh->capture({ quote_args => 1 }, @command);
        } else {
                $output = qx( @command );
        }
        return $output;
}

=head2 host_new

Add a new host to Cobbler.

@param string - name of new host
@optparam hash ref - additional options, may contain
* default => name of the system to copy from, "default" if empty
* mac     => mac address of the system, get from HostFeatures if empty

@return success - 0
@return error   - error message

=cut

sub host_new
{
        my ($self, $name, $options) = @_;
        my $default = $options->{default} || 'default';


        my $host    = model('TestrunDB')->resultset('Host')->find({name => $name});
        return "Host '$name' does not exist in the database" if not $host;

        my $mac = $options->{mac} || $self->get_mac_address($host);
        return "Missing mac address for host '$name'" if not $mac;

        my @command = split(" ","cobbler system copy --name $default --newname $name --mac-address $mac");

        return $self->cobbler_execute(@command);
}


=head2 host_del

Remove a  host from Cobbler.

@param string - name of host to remove

@return success - 0
@return error   - error message

=cut

sub host_del
{
        my ($self, $name) = @_;

        my @command = split(" ", "cobbler system remove --name $name");
        return $self->cobbler_execute(@command);
}

=head2 host_list

List systems that Cobbler already knows, either all or all matching a
given criteria.

@optparam hashref - list of criteria to match, possible criteria are
* name
* status (one of development,testing,acceptance,production)

@return success - list of system names

=cut

sub host_list
{
        my ($self, $search) = @_;

        my @command  = qw/cobbler system find/;
        if ($search and ref($search) eq 'HASH') {
        KEY:
                foreach my $key (keys %$search) {
                        push @command, "--$key", $search->{$key};
                }
        }
        return $self->cobbler_execute(@command);
}





=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=cut

1; # End of Tapper::Cmd::Cobbler
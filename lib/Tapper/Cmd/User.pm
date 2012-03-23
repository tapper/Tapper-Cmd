package Tapper::Cmd::User;
use Moose;

use Tapper::Model 'model';
use YAML::Syck;
use 5.010;

use parent 'Tapper::Cmd';

=head1 NAME

Tapper::Cmd::User - Backend functions for manipluation of user subscriptions in the database

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
users in the database. Even though it mostly handles users in the
reportsdb, some functions can also manipulate users in the testrundb.

    use Tapper::Cmd::User;

    my $user = Tapper::Cmd::User->new();
    my $details = {login => "anton",
                   name  => 'Anton Gorodetzky',
                   contacts => [{
                                 protocol => 'Mail',
                                 address  => 'anton@nightwatch.ru',
                               }]
              };
    my $id = $user->add($details);
    $details->{name} = "Anton Gorodetsky";
    my $error = $user->update($id, $details);
    $error = $user->delete($id);

    $details = {login => "anton", name  => 'Anton Gorodetzky'};
    $id = $user->add_in_testrun($details);
    $details->{name} = "Anton Gorodetsky";
    my $error = $user->update_in_testrun($id, $details);
    $error = $user->delete_in_testrun($id);



=head1 FUNCTIONS

=cut

=head2 add

Add a new user to reportsdb. Expects all details as a hash reference.


@param hash ref  - user data

@return success - user id
@return error   - undef

@throws Perl die

=cut

sub add
{
        my ($self, $data) = @_;

        my $contacts = $data->{contacts};
        delete $data->{contacts};

        $data->{login} ||= $ENV{USER};

        if (not $data->{name}) {
                # Try to guess the real name. Since UNIX has no idea of a real name, this is extremly error prone.
                my @userdata = getpwnam($data->{login});
                $data->{name} = $userdata[6];
                $data->{name} =~ s/,//g;
        }


        my $user = model('ReportsDB')->resultset('User')->new($data);
        $user->insert;

        foreach my $contact (@{$contacts || []}) {
                $contact->{user_id} = $user->id;
                my $contact_result = model('ReportsDB')->resultset('Contact')->new($contact);
                $contact_result->insert;
        }

        return $user->id;
}

=head2 list

Get a list of users with all information we have about them.

@param hash ref - search as understand by DBIx::Class

@return list of user information (hash refs)

@throws die

=cut

sub list
{
        my ($self, $search) = @_;
        my @users;
        my $user_rs = model('ReportsDB')->resultset('User')->search($search);
        while (my $user_result = $user_rs->next) {
                my $user = { id => $user_result->id, name => $user_result->name, login => $user_result->login };
                $user->{contacts} = [ map { { address => $_->address, protocol => $_->protocol } } $user_result->contacts->all ];
                push @users, $user;
        }
        return @users;

}



=head2 del

Delete a user subscription with given id. Its named del instead of
delete to prevent confusion with the buildin delete function. The first
parameter can be either the users database id (not the UNIX id!) or the
login name.

@param int|string - user id|user login name

@return success - 0

@throws die

=cut

sub del
{
        my ($self, $id) = @_;
        my $user;
        if ($id =~ /^\d+$/) {
                $user = model('ReportsDB')->resultset('User')->find($id);
        } else {
                $user = model('ReportsDB')->resultset('User')->find({login => $id});
        }
        die qq(User "$id" not found) if not $user;;
        $user->delete();
        return 0;
}

=head2 contact_add

Add a contact to an existing user in reportsdb. Expects all details as a hash
reference.

@param int|string - user as id or login
@param hash ref   - contact data

@return success - user id
@return error   - undef

@throws Perl die

=cut

sub contact_add
{
        my ($self, $user, $data) = @_;

        $user //= $ENV{USER};

        if ( $user !~ m/^\d+$/ ) {
                my $user_result = model('ReportsDB')->resultset('User')->find({login => $user});
                $user = $user_result->id;
        }
        $data->{user_id} ||= $user;

        my $contact = model('ReportsDB')->resultset('Contact')->new($data);
        $contact->insert;


        return $contact->id;
}



=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<osrc-sysin at elbe.amd.com>, or through
the web interface at L<https://osrc/bugs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=cut

1; # End of Tapper::Cmd::Testrun

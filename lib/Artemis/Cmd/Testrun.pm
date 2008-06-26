package Artemis::Cmd::Testrun;

use strict;
use warnings;

use parent 'App::Cmd';
use Artemis::Model 'model';

sub opt_spec
{
        my ( $class, $app ) = @_;

        return (
                [ 'help' => "This usage screen" ],
                $class->options($app),
               );
}

sub validate_args
{
        my ( $self, $opt, $args ) = @_;

        die $self->_usage_text if $opt->{help};
        $self->validate( $opt, $args );
}

sub _get_systems_id_for_hostname
{
        my ($name) = @_;
        return model('HardwareDB')->resultset('Systems')->search({systemname => $name})->first->lid
}

sub _get_user_for_login
{
        my ($login) = @_;

        my $user = model('TestrunDB')->resultset('User')->search({ login => $login })->first;
        return $user;
}

1;


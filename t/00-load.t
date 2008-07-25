#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Artemis::Cmd' );
}

diag( "Testing Artemis::Cmd $Artemis::Cmd::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Artemis::Cmd' );
	use_ok( 'Artemis::Cmd::Testrun' );
	use_ok( 'Artemis::Cmd::Precondition' );
}

diag( "Testing Artemis::Cmd $Artemis::Cmd::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Artemis::Cmd' );
	use_ok( 'Artemis::Cmd::Testrun' );
	use_ok( 'Artemis::Cmd::Precondition' );
	use_ok( 'Artemis::Cmd::Queue' );
}

diag( "Testing Artemis::Cmd $Artemis::Cmd::VERSION, Perl $], $^X" );

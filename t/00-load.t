#!perl

use Test::More tests => 4;

BEGIN {
	use_ok( 'Tapper::Cmd' );
	use_ok( 'Tapper::Cmd::Testrun' );
	use_ok( 'Tapper::Cmd::Precondition' );
	use_ok( 'Tapper::Cmd::Queue' );
}

diag( "Testing Tapper::Cmd $Tapper::Cmd::VERSION, Perl $], $^X" );

#!perl -T

use Test::More;

BEGIN {
        plan tests => 1;
	use_ok( 'Artemis::Cmd' );
}

diag( "Testing Artemis::Cmd $Artemis::Cmd::VERSION, Perl $], $^X" );

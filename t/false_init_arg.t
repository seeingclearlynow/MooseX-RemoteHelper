use strict;
use warnings;
use Test::More;

{
	package Test;
	use Moose;
	use MooseX::RemoteHelper;

	has attr => (
		remote_name => 'Attr',
		isa         => 'Int',
		is          => 'ro',
		required    => 1,
	);
	has thing => (
		remote_name => { far => 'thing' },
		isa         => 'Str',
		is          => 'ro',
		required    => 1,
	);

	__PACKAGE__->meta->make_immutable;
}

new_ok( 'Test' => [{ Attr => 0, thing => 'boo' }]);

done_testing;

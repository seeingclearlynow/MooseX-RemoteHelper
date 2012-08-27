use strict;
use warnings;
use Test::More;

{
	package Test;
	use Moose;
	use MooseX::RemoteHelper;

	has attr => (
		traits      => ['RemoteHelper'],
		remote_name => 'Attr',
		isa         => 'Str',
		is          => 'ro',
	);

	has thing => (
		traits      => ['RemoteHelper'],
		remote_name => { local => 'Thing', remote => 'Thingy' },
		isa         => 'Str',
		is          => 'ro',
	);
}

my $t0 = Test->new({ Attr => 'foo', Thing => 'bar' });

is $t0->attr, 'foo', 'attr matches';
is $t0->thing, 'bar', 'thing matches';

done_testing;

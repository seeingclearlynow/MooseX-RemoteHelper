use strict;
use warnings;
use Test::More;
use Test::Moose;

{
	package Role;
	use Moose::Role;
	use MooseX::RemoteHelper;

	has attr => (
		remote_name => 'attribute',
		isa         => 'Str',
		required    => 1,
		is          => 'ro',
	);

	has thing => (
		remote_name => { local => 'Thing', remote => 'Thingy' },
		isa         => 'Str',
		required    => 1,
		is          => 'ro',
	);
}
{
	package Test;
	use Moose;
	with 'Role';

	__PACKAGE__->meta->make_immutable;
}

my $t0 = Test->new({ attr => 'foo', thing => 'bar' });

isa_ok $t0, 'Test';
can_ok $t0, 'attr', 'thing', 'meta';

isa_ok my $attr0 = $t0->meta->get_attribute('attr'), 'Class::MOP::Attribute';
isa_ok my $attr1 = $t0->meta->get_attribute('thing'), 'Class::MOP::Attribute';

does_ok $attr0, 'MooseX::RemoteHelper::Meta::Trait::Attribute';
does_ok $attr1, 'MooseX::RemoteHelper::Meta::Trait::Attribute';

can_ok $attr0, 'has_remote_name', 'remote_name';
can_ok $attr1, 'has_remote_name', 'remote_name';

ok $attr0->has_remote_name, 'has remote_name';
is $attr0->remote_name, 'attribute', 'remote_name is attribute';

ok $attr1->has_remote_name, 'has remote_name';
is_deeply $attr1->remote_name, { local => 'Thing', remote => 'Thingy' }, 'remote_name matches';

my $t1 = Test->new({ attribute => 'foo', Thing => 'bar' });

is $t1->attr, 'foo', 'attr matches';
is $t1->thing, 'bar', 'thing matches';

done_testing;

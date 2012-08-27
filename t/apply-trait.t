use strict;
use warnings;
use Test::More;
use Test::Moose;

{
	package Test;
	use Moose;
	use MooseX::RemoteHelper;

	has attr => (
		isa         => 'Str',
		is          => 'ro',
		required    => 1,
		remote_name => 'attribute',
	);

has dwelling => (
		isa         => 'Str',
		is          => 'ro',
		required    => 1,
		remote_name => { here => 'apartment', there => 'flat' },
);
}

my $t0 = Test->new({ attr => 'foo', apartment => 1000 });

isa_ok $t0, 'Test';
can_ok $t0, 'meta', 'attr', 'dwelling';

isa_ok my $attr0 = $t0->meta->get_attribute('attr'), 'Class::MOP::Attribute';
isa_ok my $attr1 = $t0->meta->get_attribute('dwelling'), 'Class::MOP::Attribute';

does_ok $attr0, 'MooseX::RemoteHelper::Meta::Trait::Attribute';
does_ok $attr1, 'MooseX::RemoteHelper::Meta::Trait::Attribute';

can_ok $attr0, 'has_remote_name', 'remote_name';
can_ok $attr1, 'has_remote_name', 'remote_name';

ok $attr0->has_remote_name, 'has remote_name';
is $attr0->remote_name, 'attribute', 'remote_name is attribute';
ok $attr1->has_remote_name, 'has remote_name';
is_deeply $attr1->remote_name, { here => 'apartment', there => 'flat' }, 'remote_name matches';

done_testing;

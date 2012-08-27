use strict;
use warnings;
use Test::More;
use Test::Moose;

{
	package Test;
	use Moose;
	use MooseX::RemoteHelper;

	has attr0 => (
		isa        => 'Bool',
		is         => 'ro',
		lazy       => 1,
		default    => sub { 1 },
		serializer => sub {
			my ( $attr, $instance ) = @_;
			return $attr->get_value( $instance ) ? 'Y' : 'N';
		},
	);

	has attr1 => (
		isa         => 'Str',
		is          => 'ro',
	);

	has _attr2 => (
		isa      => 'Str',
		is       => 'bare',
		lazy     => 1,
		default  => sub { 'foo' },
		init_arg => undef,
	);

	has attr3 => (
		isa      => 'Str',
		is       => 'bare',
		lazy     => 1,
		default  => sub { 'bar' },
		remote_name => 'thing',
	);

	has attr4 => (
		isa      => 'Str',
		is       => 'bare',
		lazy     => 1,
		default  => sub { 'bar' },
		remote_name => { local => 'Thing', remote => 'Thingy' },
	);
}

subtest t0 => sub {
	my $t = Test->new;

	is $t->attr0, 1, 'attr0 is 1';

	isa_ok my $attr0 = $t->meta->get_attribute('attr0'), 'Class::MOP::Attribute';

	is $attr0->serialized( $t ),  'Y',    'attr0 serializes';
	isa_ok $t, 'Test';
};

subtest t1 => sub {
	my $t = Test->new({ attr0 => 0 });

	is $t->attr0, 0, 'attr0 is 0';

	isa_ok my $attr0 = $t->meta->get_attribute('attr0'), 'Class::MOP::Attribute';

	is $attr0->serialized( $t ),  'N',    'attr0 serializes';
	isa_ok $t, 'Test';
};

subtest t2 => sub {
	my $t = Test->new({ attr1 => 'foo' });

	is $t->attr1, 'foo', 'attr1';

	isa_ok my $attr1 = $t->meta->get_attribute('attr1'), 'Class::MOP::Attribute';

	is $attr1->serialized( $t ),  'foo',    'attr1 serializes';
	isa_ok $t, 'Test';
};

subtest t3 => sub {
	my $t = Test->new;

	isa_ok my $attr2 = $t->meta->get_attribute('_attr2'), 'Class::MOP::Attribute';

	is $attr2->serialized( $t ),  'foo',    'attr2 serializes';
	isa_ok $t, 'Test';
};

subtest t4 => sub {
	my $t = Test->new({ thing => 'baz' });

	isa_ok my $attr3 = $t->meta->get_attribute('attr3'), 'Class::MOP::Attribute';

	is $attr3->serialized( $t ),  'baz',    'attr3 serializes';
	isa_ok $t, 'Test';
};

subtest t5 => sub {
	my $t = Test->new({ Thingy => 'zoom' });

	isa_ok my $attr4 = $t->meta->get_attribute('attr4'), 'Class::MOP::Attribute';

	is $attr4->serialized( $t ),  'zoom',    'attr4 serializes';
	isa_ok $t, 'Test';
};

done_testing;

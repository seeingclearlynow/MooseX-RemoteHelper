use strict;
use warnings;
use Data::Dump 'dump';
use Test::More;
use Test::Moose;

{
	package Plain;
	use Moose;

	has some_value => (
		isa => 'Str',
		is  => 'ro',
		default => sub { 'value' },
	);

	__PACKAGE__->meta->make_immutable;
}

{
	package Composite;
	use Moose;
	use MooseX::RemoteHelper;
	with 'MooseX::RemoteHelper::CompositeSerialization';

	has sub_leaf => (
		remote_name => 'SubName',
		isa         => 'Str',
		is          => 'ro',
		default     => sub { 'Bar' },

	);
	__PACKAGE__->meta->make_immutable;
}

{
	package CompositeTop;
	use Moose;
	extends 'Composite';

	has leaf => (
		remote_name => 'Leaf',
		isa         => 'Str',
		is          => 'ro',
	);

	has true => (
		remote_name => 'SpecialBool',
		isa         => 'Bool',
		is          => 'ro',
		serializer  => sub {
			my ( $attr, $instance ) = @_;
			return $attr->get_value( $instance ) ? 'Y' : 'N';
		},
	);

	has composite => (
		remote_name => 'Composite',
		isa         => 'Object',
		is          => 'ro',
		default     => sub { Composite->new },
	);

	has plain => (
		remote_name => 'plain',
		isa     => 'Object',
		is      => 'ro',
		default => sub { Plain->new },
	);

	has not_as_plain => (
		remote_name => 'NotAsPlain',
		isa         => 'Object',
		is          => 'ro',
		default     => sub { Plain->new },
		serializer  => sub {
			my ( $attr, $instance ) = @_;
			return $attr->get_value( $instance )->some_value;
		},
	);

	has no_val => (
		remote_name => 'MyName',
		isa         => 'Str',
		is          => 'ro',
	);

	has undef => (
		remote_name => 'NotValue',
		isa         => 'Undef',
		is          => 'ro',
	);

	__PACKAGE__->meta->make_immutable;
}

my $comp
	= new_ok( 'CompositeTop' => [{
		leaf     => 'foo',
		sub_leaf => 'Baz',
		true     => 1,
		undef    => undef,
	}]);

does_ok $comp, 'MooseX::RemoteHelper::CompositeSerialization';
can_ok  $comp, 'serialize';

my %expected = (
	Leaf        => 'foo',
	SubName     => 'Baz',
	SpecialBool => 'Y',
	NotValue    => undef,
	NotAsPlain  => 'value',
	Composite => {
		SubName => 'Bar',
	},
);

is_deeply $comp->serialize, \%expected, 'serialize';

{
package Blah;

use Moose;
use MooseX::RemoteHelper;

with 'MooseX::RemoteHelper::CompositeSerialization';

has succeeded => (
	isa         => 'Bool',
	is          => 'rw',
	default     => 1,
	required    => 0,
	remote_name => { local => 'successful', remote => 'is_success' },
	serializer => sub {
		my ( $attr, $instance, $remote ) = @_;

		( defined $remote && $remote eq 'local' ) ?
			return $attr->get_value( $instance ) ? 'y' : 'n'
		:
			return $attr->get_value( $instance ) ? 'true' : 'false'
		;
	},
	lazy        => 1,
);

has plain => (
	isa         => 'Object',
	is          => 'rw',
	default     => sub { Plain->new() },
	required    => 0,
	remote_name => { local => 'ordinary', remote => 'regular' },
	serializer => sub {
		my ( $attr, $instance ) = @_;

		return $attr->get_value( $instance )->some_value();
	},
	lazy        => 1,
);

has compit => (
	isa         => 'CompositeTop',
	is          => 'rw',
	default     => sub {
		return CompositeTop->new( {
			leaf     => 'foo',
			sub_leaf => 'Baz',
			true     => 1,
			undef    => undef,
		} )
	},
	required    => 0,
	remote_name => { local => 'ct', remote => 'target_test' },
	init_arg  => undef,
	serializer => sub {
		my ( $attr, $instance, $remote ) = @_;

		if ( defined $remote && $remote eq 'local' ) {
			return $attr->get_value( $instance )->serialize( $remote );
		}
		else {
			return {};
		}
	},
	lazy        => 1,
);
}

my $thing = Blah->new( successful => 0 );

my $hash     = {
	succeeded  =>  'false',
	plain      => 'value',
	compit     => {},
};

is $thing->succeeded(), 0, 'succeeded is false';
is_deeply $thing->serialize(), $hash, 'Object serializes properly';

$hash        = {
	successful => 'n',
	ordinary   => 'value',
	ct         => \%expected,
};

is_deeply $thing->serialize( 'local' ), $hash, 'Object serializes properly';

$hash         = {
	is_success  => 'false',
	regular     => 'value',
	target_test => {},
};

is_deeply $thing->serialize( 'remote' ), $hash, 'Object serializes properly';

done_testing;

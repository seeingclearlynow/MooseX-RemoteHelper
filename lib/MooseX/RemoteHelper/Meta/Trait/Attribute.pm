package MooseX::RemoteHelper::Meta::Trait::Attribute;
use strict;
use warnings;
use namespace::autoclean;

# VERSION

use Moose::Role;
Moose::Util::meta_attribute_alias 'RemoteHelper';

has remote_name => (
	predicate => 'has_remote_name',
	isa       => 'Str|HashRef',
	is        => 'ro',
);

has serializer => (
	predicate => 'has_serializer',
	traits    => ['Code'],
	is        => 'bare',
	handles   => {
		serializing => 'execute_method',
	},
);

sub serialized {
	my ( $self, $instance ) = @_;

	return $self->has_serializer
		? $self->serializing( $instance )
		: $self->get_value( $instance )
		;
}

around initialize_instance_slot => sub {
	my ( $orig, $self )          = ( shift, shift );
	my ( undef, undef, $params ) = @_;

	return $self->$orig(@_)
		unless $self->has_remote_name ## no critic ( ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions )
			&& $self->has_init_arg
			&& (
				( ref $self->remote_name() eq ''
				&& $self->remote_name ne $self->init_arg
				)
				|| ( ref $self->remote_name() eq 'HASH'
					&& scalar values $self->remote_name == 1
					&& ( values $self->remote_name() )[0] ne $self->init_arg()
				)
			)
			;

	# move values referred to by remote names to their corresponding init_args
	my $arg                      = $self->init_arg();

	my $remote                 = $self->remote_name();

	if ( ref $remote eq '' ) {
		$params->{ $arg } = delete $params->{ $remote } if $params->{ $remote };
	}
	else { # remote_name is a hash
		foreach my $item ( values %$remote ) {
			$params->{ $arg } = delete $params->{ $item } if $params->{ $item };
		}
	}

	$self->$orig(@_);
};

1;

# ABSTRACT: role applied to meta attribute

=method serialized

returns the attributed value by using the L<serializer|/serializer>.

=attr remote_name

the name of the attribute key on the remote host. if no C<remote_name> is
provided it should be assumed that the attribute is not used on the remote but
is instead local only. L<MooseX::RemoteHelper::CompositeSerialization> will
not serialize an attribute that doesn't have a C<remote_name>

	has perlish => (
		isa         => 'Str',
		remote_name => 'MyReallyJavaIshKey',
		is          => 'ro',
	);

=attr serializer

a code ref for converting the real value to what the remote host expects. it
requires that you pass the attribute and the instance. e.g.

	has foo_bar => (
		isa         => 'Bool',
		remote_name => 'FooBar',
		serializer  => sub {
			my ( $attr, $instance ) = @_;
			return $attr->get_value( $insance ) ? 'T' : 'F';
		},
	);

=cut

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
	my ( $self, $instance, $remote ) = @_;

	return $self->has_serializer
		? $self->serializing( $instance, $remote )
		: $self->get_value( $instance )
		;
}

around initialize_instance_slot => sub {
	my ( $orig, $self )          = ( shift, shift );
	my ( undef, undef, $params ) = @_;

	# Nothing to do if no remote names differ from the init arg value
	if ( $self->has_init_arg() && $self->has_remote_name() ) {
		my $arg                      = $self->init_arg();
		my $remote                 = $self->remote_name();

		# move values referred to by remote names to their corresponding init_args
		if ( ref $remote eq '' ) {
			$params->{ $arg } = delete $params->{ $remote }
				if defined $params->{ $remote } && $remote ne $arg;
		}
		else {
			if ( ref $remote eq 'HASH' ) {
				foreach my $item ( values %$remote ) {
					$params->{ $arg } = delete $params->{ $item }
						if defined $params->{ $item } && $item ne $arg;
				}
			}
		}
	}

	return $self->$orig( @_ );
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

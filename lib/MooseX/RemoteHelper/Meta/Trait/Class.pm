package MooseX::RemoteHelper::Meta::Trait::Class;
use strict;
use warnings;
use namespace::autoclean;

# VERSION

use Moose::Role;

around _inline_slot_initializer => sub {
	my ( $orig, $self ) = ( shift, shift );
	my ( $attr )        = @_;
	my @orig_source     = $self->$orig(@_);

	return @orig_source
		unless $attr->meta->can('does_role')
			&& $attr->meta->does_role('MooseX::RemoteHelper::Meta::Trait::Attribute')
			;

	if ( $attr->has_remote_name() && $attr->has_init_arg() ) {
		my $arg           = $attr->init_arg;
		my $remote        = $attr->remote_name();
		my $code          = '';

		if ( ref $remote eq '' ) {
			$code =
				"\$params->{$arg} = delete \$params->{$remote} if defined \$params->{$remote};";
		}
		elsif ( ref $remote eq 'HASH' ) {
			foreach my $key ( values %$remote ) {
				$code .= "\$params->{$arg} = delete \$params->{$key} if ( \$params->{$key} && '$key' ne '$arg' );\n";
			}
		}

		return ( $code, @orig_source );
	}

	return @orig_source;
};

1;
# ABSTRACT: meta class for immutable objects

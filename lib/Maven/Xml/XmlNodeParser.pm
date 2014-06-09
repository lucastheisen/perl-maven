use strict;
use warnings;

package Maven::Xml::XmlNodeParser;

use parent qw(Class::Accessor);

use XML::LibXML::Reader qw(:types);

sub new {
    return bless( {}, shift )->_init( @_ );
}

sub _add_value {
    my ($self, $name, $value) = @_;

    if ( defined( $self->{$name} ) ) {
        my $existing = $self->{$name};
        if ( ref( $existing ) eq 'ARRAY' ) {
            push( @$existing, $value );
        }
        else {
            my @values = ($existing, $value);
            $self->{$name} = \@values;
        }
    }
    else {
        $self->{$name} = $value;
    }
}

sub _init {
    return $_[0];
}

sub _get_parser {
    return $_[0];
}

sub _parse_node {
    my ($self, $reader, $types) = @_;

    my $name;
    my $value;
    while ( $reader->read() ) {
        if ( $reader->nodeType() == XML_READER_TYPE_ELEMENT ) {
            $name = $reader->name();
            if ( $reader->isEmptyElement() ) {
                $self->_add_value( $name, undef ); 
            }
            else {
                $self->_add_value( $name, 
                    $self->_get_parser( $name )->_parse_node( $reader ) );
            }
            $value = $self;
        }
        elsif ( $reader->nodeType() == XML_READER_TYPE_TEXT
            || $reader->nodeType() == XML_READER_TYPE_CDATA ) {
            $value = $reader->value();
        }
        elsif ( $reader->nodeType() == XML_READER_TYPE_END_ELEMENT ) {
            return $value;
        }
    }
}

1;

__END__
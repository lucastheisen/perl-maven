use strict;
use warnings;

package Maven::Xml::Pom::DependencyManagement;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    dependencies
));

sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'dependencies' );

    if ( $name eq 'dependency' ) {
        push( @{$self->{dependencies}}, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'dependency' ) {
        return Maven::Xml::Pom::Dependency->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser( $name );
}

1;
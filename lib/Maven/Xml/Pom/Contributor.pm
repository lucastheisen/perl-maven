use strict;
use warnings;

package Maven::Xml::Pom::Contributor;

# ABSTRACT: Maven Contributor element
# PODNAME: Maven::Xml::Pom::Contributor

use Maven::Xml::Common::Properties;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    name
    email
    url
    organization
    organizationUrl
    roles
    timezone
    properties
));

sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'roles' );

    if ( $name eq 'role' ) {
        push( @{$self->{roles}}, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'properties' ) {
        return Maven::Xml::Common::Properties->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser( $name );
}

1;

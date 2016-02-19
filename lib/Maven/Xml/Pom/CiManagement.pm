use strict;
use warnings;

package Maven::Xml::Pom::CiManagement;

# ABSTRACT: Maven CiManagement element
# PODNAME: Maven::Xml::Pom::CiManagement

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    system
    url
    notifiers
));

sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'notifiers' );

    if ( $name eq 'notifier' ) {
        push( @{$self->{notifiers}}, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'notifier' ) {
        return Maven::Xml::Pom::CiManagement::Notifier->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser( $name );
}

package Maven::Xml::Pom::CiManagement::Notifier;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    type
    sendOnError
    sendOnFailure
    sendOnSuccess
    sendOnWarning
    configuration
));

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'configuration' ) {
        return Maven::Xml::Common::Configuration->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser( $name );
}

1;

use strict;
use warnings;

package Maven::Xml::Pom::Dependencies;
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;

sub _add_value {
    my ($self, $name, $value) = @_;

    if ( $name eq 'dependency' ) {
        $self->{$value->_key( $name )} = $value;
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

package Maven::Xml::Pom::Dependency;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    artifactId
    classifier
    exclusions
    groupId
    optional
    scope
    systemPath
    type
    version
));

sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'exclusions' );

    if ( $name eq 'exclusion' ) {
        push( @{$self->{exclusions}}, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'exclusion' ) {
        return Maven::Xml::Pom::Dependency::Exclusion->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser( $name );
}

sub _key {
    my ($self, $default) = @_;
    return join( ':', 
        $self->{groupId},
        $self->{artifactId},
        ($self->{type} || 'jar'),
        ($self->{classifier} || '') );
}

package Maven::Xml::Pom::Dependency::Exclusion;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    groupId
    artifactId
));

1;
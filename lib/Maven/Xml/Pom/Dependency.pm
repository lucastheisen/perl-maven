use strict;
use warnings;

package Maven::Xml::Pom::Dependency;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    groupId
    artifactId
    version
    classifier
    type
    scope
    systemPath
    optional
    exclusions
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

package Maven::Xml::Pom::Dependency::Exclusion;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    groupId
    artifactId
));

1;
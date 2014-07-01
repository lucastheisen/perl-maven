use strict;
use warnings;


package Maven::Xml::Common::BaseProfile;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    activation
    id
    pluginRepositories
    properties
    repositories
));
  
sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'profile' );
    return if ( $name eq 'repositories' );
    return if ( $name eq 'pluginRepositories' );

    if ( $name eq 'repository' ) {
        push( @{$self->{repositories}}, $value );
    }
    elsif ( $name eq 'pluginRepository' ) {
        push( @{$self->{pluginRepositories}}, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'activation' ) {
        return Maven::Xml::Common::BaseProfile::Activation->new();
    }
    if ( $name eq 'properties' ) {
        return Maven::Xml::Common::Properties->new();
    }
    if ( $name eq 'repository' ) {
        return Maven::Xml::Common::Repository->new();
    }
    if ( $name eq 'pluginRepository' ) {
        return Maven::Xml::Common::Repository->new();
    }
    return $self;
}

package Maven::Xml::Common::BaseProfile::Activation;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    activeByDefault
    file
    jdk
    os
    property
));

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'os' ) {
        return Maven::Xml::Common::BaseProfile::Activation::Os->new();
    }
    if ( $name eq 'property' ) {
        return Maven::Xml::Common::BaseProfile::Activation::Property->new();
    }
    if ( $name eq 'file' ) {
        return Maven::Xml::Common::BaseProfile::Activation::File->new();
    }
    return $self;
}

package Maven::Xml::Common::BaseProfile::Activation::Os;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    arch
    name
    family
    version
));

package Maven::Xml::Common::BaseProfile::Activation::Property;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    name
    value
));

package Maven::Xml::Common::BaseProfile::Activation::File;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    exists
    missing
));

1;

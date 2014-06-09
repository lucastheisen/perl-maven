use strict;
use warnings;

package Maven::Xml::Pom::Build;

use parent qw(Maven::Xml::Pom::BaseBuild);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    sourceDirectory
    scriptSourceDirectory
    testSourceDirectory
    outputDirectory
    testOutputDirectory
    extensions
));

sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'extensions' );

    if ( $name eq 'extension' ) {
        push( @{$self->{extensions}}, $value );
    }
    else {
        $self->Maven::Xml::Pom::BaseBuild::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'extension' ) {
        return Maven::Xml::Pom::Build::Extension->new();
    }
    return $self->Maven::Xml::Pom::BaseBuild::_get_parser( $name );
}

package Maven::Xml::Pom::Build::Extension;

use parent qw(Maven::Xml::Pom::BaseBuild);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    groupId
    artifactId
    version
));

1;
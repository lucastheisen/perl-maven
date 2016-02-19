use strict;
use warnings;

package Maven::Xml::Pom::DependencyManagement;

# ABSTRACT: Maven DependencyManagement element
# PODNAME: Maven::Xml::Pom::DependencyManagement

use Maven::Xml::Pom::Dependencies;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    dependencies
));

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'dependencies' ) {
        return Maven::Xml::Pom::Dependencies->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser( $name );
}

1;

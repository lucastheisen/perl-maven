use strict;
use warnings;

package Maven::Xml::Common::Repository;

# ABSTRACT: Maven Repositories element
# PODNAME: Maven::Xml::Common::Repository

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    releases
    snapshots
    id
    name
    url
    layout
));

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'releases' ) {
        return Maven::Xml::Common::Repository::RepositoryPolicy->new();
    }
    if ( $name eq 'snapshots' ) {
        return Maven::Xml::Common::Repository::RepositoryPolicy->new();
    }
    return $self;
}

package Maven::Xml::Common::Repository::RepositoryPolicy;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    enabled
    updatePolicy
    checksumPolicy
));

1;

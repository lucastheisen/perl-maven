use strict;
use warnings;

package Maven::Xml::Pom::DistributionManagement;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    repository
    snapshotRepository
    site
    relocation
    downloadUrl
    status
));

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'repository' ) {
        return Maven::Xml::Pom::DistributionManagement::Repository->new();
    }
    elsif ( $name eq 'snapshotRepository' ) {
        return Maven::Xml::Pom::DistributionManagement::Repository->new();
    }
    elsif ( $name eq 'site' ) {
        return Maven::Xml::Pom::DistributionManagement::Site->new();
    }
    elsif ( $name eq 'relocation' ) {
        return Maven::Xml::Pom::DistributionManagement::Relocation->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser( $name );
}

package Maven::Xml::Pom::DistributionManagement::Repository;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    id
    name
    uniqueVersion
    url
    layout
));

package Maven::Xml::Pom::DistributionManagement::Site;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    id
    name
    url
));

package Maven::Xml::Pom::DistributionManagement::Relocation;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    groupId
    artifactId
    version
    message
));

1;
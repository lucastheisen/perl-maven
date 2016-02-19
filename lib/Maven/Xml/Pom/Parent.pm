use strict;
use warnings;

package Maven::Xml::Pom::Parent;

# ABSTRACT: Maven Parent element
# PODNAME: Maven::Xml::Pom::Parent

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    groupId
    artifactId
    version
    relativePath
));

1;

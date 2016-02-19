use strict;
use warnings;

package Maven::Xml::Pom::Scm;

# ABSTRACT: Maven Scm element
# PODNAME: Maven::Xml::Pom::Scm

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    connection
    developerConnection
    url
    tag
));

1;

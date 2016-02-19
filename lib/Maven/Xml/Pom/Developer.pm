use strict;
use warnings;

package Maven::Xml::Pom::Developer;

# ABSTRACT: Maven Developer element
# PODNAME: Maven::Xml::Pom::Developer

use parent qw(Maven::Xml::Pom::Contributor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    id
));

1;

use strict;
use warnings;

package Maven::Xml::Pom::License;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    name
    url
    distribution
    comments
));

1;
use strict;
use warnings;

package Maven::Xml::Pom::IssueManagement;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    system
    url
));

1;
use strict;
use warnings;

package Maven::Xml::Common::Configuration;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;

sub _get_parser {
    return Maven::Xml::Common::Configuration->new();
}

1;
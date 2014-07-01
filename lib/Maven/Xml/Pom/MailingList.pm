use strict;
use warnings;

package Maven::Xml::Pom::MailingList;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    name
    subscribe
    unsubscribe
    post
    archive
    otherArchives
));

sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'otherArchives' );

    if ( $name eq 'otherArchive' ) {
        push( @{$self->{otherArchives}}, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

1;
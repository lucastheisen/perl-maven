use strict;
use warnings;

package Maven::Xml::XmlFile;

use parent qw(Maven::Xml::XmlNodeParser);

use Carp;
use Log::Any;
use XML::LibXML::Reader;

my $logger = Log::Any->get_logger();

sub _init {
    my ($self, %options) = @_;

    my $xml_string = $options{string};
    if ( !$xml_string && $options{file} ) {
        $logger->debugf( 'loading xml from file %s', $options{file} );
        # http://www.perl.com/pub/2003/11/21/slurp.html
        $xml_string = do { local( @ARGV, $/ ) = $options{file}; <> };
    }
    if ( !$xml_string && $options{url} ) {
        $logger->debugf( 'loading xml from uri %s', $options{url} );
        my $agent = $options{agent};
        if ( !$agent ) { 
            require Maven::LwpAgent;
            $agent = Maven::LwpAgent->new();
        }
    
        my $response = $agent->get( $options{url} );
        if ( ! $response->is_success() ) {
            if ( $options{die_on_failure} ) {
                die( $response );
            }
            else {
                return;
            }
        }
        
        $xml_string = $response->content();
    }

    $self->_parse_node( XML::LibXML::Reader->new( string => $xml_string ) );
    
    return $self;
}

1;

__END__

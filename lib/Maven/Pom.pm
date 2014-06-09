use strict;
use warnings;

package Maven::Pom;

use Carp;
use Data::Dumper;
use File::ShareDir;
use Log::Any;
use Maven::LocalRepository;

use parent qw(Maven::Xml::Pom);
use overload fallback => 1,
    q{""} => 'to_string';

my $logger = Log::Any->get_logger();
my $superpom;

sub _get_parent_pom {
    my ($self, $repositories) = @_;

    my $parent = $self->{parent};
    if ( $parent ) {
        croak( "unable to lookup parent" ) if ( ! $repositories );
        my $parent_artifact = $repositories->resolve(
            groupId => $parent->{groupId},
            artifactId => $parent->{artifactId},
            version => $parent->{version}
        );
        return Maven::Xml::Pom->new( uri => $parent_artifact->get_url() );
    }
    else {
        if ( ! $superpom ) {
            $superpom = Maven::Xml::Pom->new( file => 
                File::ShareDir::module_file( 'Maven::Xml::Pom', 'superpom.xml' ) );
        }

        if ( \$self == \$superpom ) {
            return;
        }
        else {
            return $superpom;
        }
    }
}

sub _init {
    my ($self, %options) = @_;
    
    my $pom_artifact = $options{repositories}->resolve( '', %options );
    
    $self->Maven::Xml::Pom::_init( uri => $pom_artifact->get_url() );

    my $parent = $self->_get_parent_pom( $options{repositories} );
    if ( $parent ) {
        print( "REMOVE ME: merge!\n" );
    }
    
    return $self;
}

sub to_string {
    my ($self) = @_;
    return Dumper( $self );
}

1;

__END__
use overload fallback => 1,
    q{""} => 'to_string';
            
use Carp;
use Data::Dumper;
use File::ShareDir;
use Log::Any;
use XML::LibXML::Reader qw(:states :types);

my $logger = Log::Any->get_logger();
my %loaded =  ();

sub new {
    return bless( {}, shift )->_init( @_ );
}

sub _add_value {
    my ($hashref, $name, $value) = @_;

    $hashref = {} if ( ! $hashref );

    if ( defined( $hashref->{$name} ) ) {
        my $existing = $hashref->{$name};
        if ( ref( $existing ) eq 'ARRAY' ) {
            push( @$existing, $value );
        }
        else {
            my @values = ($existing, $value);
            $hashref->{$name} = \@values;
        }
    }
    else {
        $hashref->{$name} = $value;
    }
    
    return $hashref;
}

sub _init {
    my ($self, %options) = @_;

    $self->{repositories} = $options{repositories}
        || Maven::Repositories->new()->add_local_repository();

    my $xml_string = $options{string};
    if ( $options{file} ) {
        $logger->debugf( 'loading pom from %s', $options{file} );
        $xml_string = do { local( @ARGV, $/ ) = $options{file}; <> };
    }
    if ( $options{uri} ) {
        $logger->debugf( 'loading pom from %s', $options{uri} );
        my $agent = $options{agent} || LWP::UserAgent->new();
    
        my $response = $agent->get( $options{uri} );
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

    $self->{pom} = _parse_node( XML::LibXML::Reader->new( string => $xml_string ) );
    
    return $self;
}

sub get_parent {
    my ($self) = @_;
    $logger->tracef( '[%s] get_parent()', $self );

    if ( ! exists( $self->{parent} ) ) {
        $logger->tracef( '[%s] checking for parent', $self );
        if ( $self->{pom}{project}{parent} ) {
            $logger->tracef( '[%s] has parent', $self );
            my $artifact = $self->{repositories}->resolve( '', 
                groupId => $self->{pom}{project}{parent}{groupId},
                artifactId => $self->{pom}{project}{parent}{artifactId},
                version => $self->{pom}{project}{parent}{version},
                packaging => 'pom'
            );
            croak( "unable to locate parent" ) if ( ! $artifact );

            $logger->tracef( '[%s] found parent: %s', $self, $artifact );
            my $coordinate = $artifact->get_coordinate();
            if ( ! exists( $loaded{$coordinate} ) ) {
                $logger->tracef( '[%s] loading parent: %s', $self, $artifact );
                $loaded{$coordinate} = Maven::Pom->new( 
                    repositories => $self->{repositories},
                    uri => $artifact->get_uri() );
                $self->{parent} = $loaded{$coordinate};
            }
            else {
                $logger->tracef( '[%s] parent found in cache: %s', $self, $artifact );
                $self->{parent} = $loaded{$coordinate};
            }
        }
        else {
            # superpom
            if ( ! exists( $loaded{superpom} ) ) {
                $loaded{superpom} = {};
                $logger->trace( 'loading superpom' );
                $loaded{superpom} = Maven::Pom->new(
                    repositories => $self->{repositories},
                    file => File::ShareDir::module_file( 
                        __PACKAGE__, 'superpom.xml' ) );

                # superpom has no parent, so stop recursion...
                $loaded{superpom}{parent} = undef; 
            }
            $self->{parent} = $loaded{superpom};
        }
    }
    return $self->{parent};
}

sub get_property {
    my ($self, $coordinate, $skip_recurse) = @_;
    $logger->tracef( '[%s] get_property(%s)', $self, $coordinate );
    
    my $value;
    
    if ( $coordinate eq 'project.basedir' ) {
        return '#{project.basedir}';
    }
    if ( $coordinate eq 'project.parent.basedir' ) {
        return '#{project.parent.basedir}';
    }
    if ( $coordinate eq 'project.packaging' ) {
        $value = $self->{pom}{project}{packaging} || 'jar';
    }

    # check for value in properties
    if ( $self->{pom}{project}{properties} ) {
        $value = $self->{pom}{project}{properties}{$coordinate};
    }
    if ( $coordinate =~ /^project\.properties\.(.*)$/ ) {
        $value = $self->{pom}{project}{properties}{$1};
    }
    if ( $coordinate =~ /^project\.parent\.(.*)$/ ) {
        my $parent = $self->get_parent();
        if ( $parent ) {
            $parent->get_property( "project.$1" );
        }
    }

    if ( ! $value ) {
        my $found = 1;
        
        # check for value at coordinate
        $value = $self->{pom};
        foreach my $coordinate_part ( split( /\./, $coordinate ) ) {
            my $child = $value->{$coordinate_part};
            if ( ! $child ) {
                $found = 0;
                last();
            }
            $value = $child;
        }
        
        # not found, check parent
        if ( !$found ) {
            my $parent = $self->get_parent();
            if ( $parent ) {
                $logger->tracef( '[%s] checking parent %s for %s', $self, $parent, $coordinate );
                my $parent_value = $parent->get_property( $coordinate, 1 );
                if ( defined( $parent_value ) ) {
                    $value = $parent_value;
                    $found = 1;
                }
            }
        }
        
        $value = undef if ( !$found );
    }

    if ( $value ) {
        if ( $skip_recurse ) {
            return $value;
        }
        else {
            # resolve any placeholders
            if ( ref( $value ) eq 'HASH' ) {
                my $copy = {};
                foreach my $key ( keys( %$value ) ) {
                    $copy->{$key} = $self->get_property( "$coordinate.$key" );
                }
                return $copy;
            }
            elsif( ref( $value ) eq 'ARRAY' ) {
                my @copy = (); 
                foreach my $entry ( @$value ) {
                    $entry =~ s/\$\{(.*?)\}/$self->get_property($1)/eg;
                    push( @copy, $entry );
                }
                return \@copy;
            }
            else {
                while ( scalar( $value =~ s/\$\{(.*?)\}/$self->get_property($1, 1)/eg ) ) {}
                return $value;
            }
        }
    }
    else {
        return "\${$coordinate}";
    }
}

sub _parse_node {
    my ($reader) = @_;

    my $name;
    my $value;
    while ( $reader->read() ) {
        if ( $reader->nodeType() == XML_READER_TYPE_ELEMENT ) {
            $name = $reader->name();
            $value = _add_value( $value, $name, _parse_node( $reader ) );
        }
        elsif ( $reader->nodeType() == XML_READER_TYPE_TEXT
            || $reader->nodeType() == XML_READER_TYPE_CDATA ) {
            $value = $reader->value();
        }
        elsif ( $reader->nodeType() == XML_READER_TYPE_END_ELEMENT ) {
            return $value;
        }
    }
    
    return $value;
}

sub to_string {
    my ($self) = @_;
    return join( ':',
        $self->{pom}{project}{groupId} || '',
        $self->{pom}{project}{artifactId} || '',
        $self->{pom}{project}{version} || '' );
}

1;

__END__
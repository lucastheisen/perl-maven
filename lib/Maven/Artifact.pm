use strict;
use warnings;

package Maven::Artifact;

# ABSTRACT: An maven artifact definition
# PODNAME: Maven::Artifact

use overload fallback => 1,
    q{""} => 'to_string';
use parent qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
        qw(groupId artifactId version classifier artifact_name url));

use Carp qw(croak);
use File::Copy;
use File::Temp;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    my ($class, @args) = @_;
    return bless( {}, $class )->_init( @args );
}

sub download {
    my ($self, %options) = @_;

    croak( "url not set, perhaps you forgot to resolve?" ) if ( ! $self->{url} );

    my $file;
    if ( $options{to} ) {
        $file = $options{to};
        if ( -d $file ) {
            $file = File::Spec->catfile( $file, "$self->{artifactId}." . $self->get_packaging() );
        }
    }

    my $uri = $self->get_uri();
    if ( $uri->scheme() =~ /^file$/i 
        && ( $uri->host() eq '' || $uri->host() =~ /^localhost$/ ) ) {
        $logger->debugf( 'found local copy of %s', $self->{artifactId} );
        if ( $file ) {
            $logger->tracef( 'copy from %s to %s', $uri->path(), $file );
            copy( $uri->path(), $file ) || croak( "failed to copy file $!" );
        }
        else {
            $file = $uri->path();
        }
    }
    else {
        $logger->debugf( 'downloading %s from %s', $self->{artifactId}, $uri->as_string() );
        $file = File::Temp->new() if ( !$file );
        my $agent = $options{agent} || LWP::UserAgent->new();
        my $response = $agent->get( $uri, 
            ':content_file' => ref($file) eq 'File::Temp' ? $file->filename() : $file );
    }

    return $file;
}

sub get_coordinate {
    my ($self) = @_;
    
    return join( ':',
        $self->get_groupId() || '',
        $self->get_artifactId() || '',
        $self->get_packaging() || '',
        $self->get_classifier() || '',
        $self->get_version() || '' );
}

sub get_packaging {
    return shift->{packaging} || 'jar';
}

sub get_uri {
    my ($self) = @_;

    if ( ! $self->{uri} ) {
        $self->{uri} = URI->new( $self->{url} );
    }

    return $self->{uri};
}

sub _init {
    my ($self, $coordinate, %parts ) = @_;

    if ( !(ref( $coordinate ) eq 'HASH') ) {
        # coordinate order is specified per 
        # https://maven.apache.org/pom.html#Maven_Coordinates
        my @parts = split( /:/, $coordinate, -1 );
        my $count = scalar( @parts );

        $coordinate = {
            groupId => $parts[0],
            artifactId => $parts[1]
        };

        # Version could be empty string implying we should detect the latest
        # so dont set it here.
        if ( $count == 3 ) {
            $coordinate->{version} = $parts[2] if ( $parts[2] );
        }
        elsif ( $count == 4 ) {
            $coordinate->{packaging} = $parts[2];
            $coordinate->{version} = $parts[3] if ( $parts[3] );
        }
        elsif ( $count == 5 ) {
            $coordinate->{packaging} = $parts[2];
            $coordinate->{classifier} = $parts[3];
            $coordinate->{version} = $parts[4] if ( $parts[4] );
        }

        foreach my $part ( keys( %parts ) ) {
            # only set the part if it has a non-empty value
            my $part_value = $parts{$part};
            if ( $part_value ) {
                $logger->tracef( 'setting %s to \'%s\'', $part, $part_value );
                $coordinate->{$part} = $part_value;
            }
        }
    }

    $self->{groupId} = $coordinate->{groupId};
    $self->{artifactId} = $coordinate->{artifactId};
    $self->{version} = $coordinate->{version};
    $self->{packaging} = $coordinate->{packaging};
    $self->{classifier} = $coordinate->{classifier};

    return $self;
}

sub set_packaging {
    my ($self, $packaging) = @_;
    $self->{packaging} = $packaging;
}

sub to_string {
    return $_[0]->get_coordinate();
}

1;

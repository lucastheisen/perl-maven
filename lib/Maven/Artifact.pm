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
    return bless({}, $class)->_init(@args);
}

sub download {
    my ($self, %options) = @_;

    croak("url not set, perhaps you forgot to resolve?") if (! $self->{url});

    my $agent;
    if ($options{agent}) {
        if ($options{agent}->isa('Maven::Agent')) {
            $agent = $options{agent};
        }
        elsif ($options{agent}->isa('Maven::Maven')) {
            $agent = $options{agent}
                ->get_repositories()
                ->get_repository($self->{url})
                ->get_agent();
        }
        elsif ($options{agent}->isa('Maven::Repositories')) {
            $agent = $options{repositories}
                ->get_repository($self->{url})
                ->get_agent();
        }
        elsif ($options{agent}->isa('Maven::Repository')) {
            $agent = $options{repository}
                ->get_agent();
        }
        elsif ($options{agent}->isa('LWP::UserAgent')) {
            $agent = Maven::LwpAgent->new(agent => $agent);
        }
        else {
            croak('unsupported agent ', ref($options{agent}));
        }
    }
    else {
        require Maven::LwpAgent;
        $agent = Maven::LwpAgent->new();
    }
    
    return $agent->download($self, %options);
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
            $coordinate->{classifier} = $parts[3] if ( $parts[3] );
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

sub is_complete {
    my ($self) = @_;
    $self->{groupId} && $self->{artifactId} && $self->{version} ? 1 : 0;
}

sub set_packaging {
    my ($self, $packaging) = @_;
    $self->{packaging} = $packaging;
}

sub to_string {
    return $_[0]->get_coordinate();
}

package Maven::Artifact::DownloadedFile;

# Wraps a downloaded file that way if it is a temp file it will hold a 
# reference to the temp file handle so as to keep the destructor from
# getting called.  It will provide the filename when used as a string.

use overload q{""} => 'filename', fallback => 1;

sub new {
    my $self = bless( {}, shift );
    my $file = shift;
    
    if ( ref($file) eq 'File::Temp' ) {
        $self->{handle} = $file;
        $self->{name} = $file->filename();
    }
    else {
        $self->{name} = $file;
    }
    
    return $self;
}

sub filename {
    return $_[0]->{name};
}

1;

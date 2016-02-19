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

sub get_coordinate {
    my ($self) = @_;
    
    return join(':',
        $self->get_groupId() || (),
        $self->get_artifactId() || (),
        $self->get_packaging() || (),
        $self->get_classifier() || (),
        $self->get_version() || ());
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

sub set_packaging {
    my ($self, $packaging) = @_;
    $self->{packaging} = $packaging;
}

sub to_string {
    return $_[0]->get_coordinate();
}

1;

__END__
=head1 SYNOPSIS

    use Maven::Artifact;

    my $artifact = Maven::Artifact->new('javax.servlet:servlet-api:2.5);

    my $artifact = Maven::Artifact->new('javax.servlet:servlet-api',
        version => 2.5
        packaging => 'jar');

Or, more commonly:

    use Maven::Agent;

    my $agent = Maven::Agent->new();
    my $artifact = $agent->resolve('javax.servlet:servlet-api:2.5);

=head1 DESCRIPTION

Represents a maven artifact.  Artifacts are identified by coordinates.  An
artifacts coordinate is made up of: 
L<groupId:artifactId[:packaging[:classifier]]:version|https://maven.apache.org/pom.html#Maven_Coordinates>
Packaging and classifier are optional, and if not specified, then packaging
defaults to C<jar> and classifier is left empty.  This representation also
contains a uri that is specified by when this artifact gets 
L<resolved|Maven::Agent/"resolve($artifact, [%parts])">.

=constructor new($artifact, %parts)

Returns a new artifact indicated by C<$artifact>.  If C<%parts> are supplied,
their values will be used to override the corresponding values in C<$artifact>
before resolution is attempted.

=method get_artifactId()

Returns the C<artifactId>.

=method get_artifact_name()

Returns the C<artifact_name>.

=method get_classifier()

Returns the C<classifier>.

=method get_coordinate()

Returns the coordinate representation of this artifact.

=method get_groupId()

Returns the C<groupId>.

=method get_packaging()

Returns the C<packaging>.

=method get_uri()

Returns the C<url> as an L<URI> object.

=method get_url()

Returns the C<url>.

=method get_version()

Returns the C<version>.

=method set_groupId($group_id)

Sets the C<groupId> to C<$group_id>.

=method set_artifactId($artifact_id)

Sets the C<artifactId> to C<$artifact_id>.

=method set_artifact_name($artifact_name)

Sets the C<artifact_name> to C<$artifact_name>.

=method set_classifier($classifier)

Sets the C<classifier> to C<$classifier>.

=method set_packaging($packaging)

Sets the C<packaging> to C<$packaging>.

=method set_url($url)

Sets the C<url> to C<$url>.

=method set_version($version)

Sets the C<version> to C<$version>.

=method to_string()

Returns the value of L<get_coordinate|/get_coordinate()>.

=head1 SEE ALSO
Maven::Agent
Maven::MvnAgent
Maven::Artifact
Maven::Maven

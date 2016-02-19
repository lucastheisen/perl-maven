use strict;
use warnings;

package Maven::Repositories;

# ABSTRACT: An ordered collection of repositories from which to resolve artifacts
# PODNAME: Maven::Repositories

use parent qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(repositories));

use Carp;
use Log::Any;
use Maven::LocalRepository;
use Maven::RemoteRepository;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init( @_ );
}

sub add_central {
    my ($self, @args) = @_;
    $logger->debug( "adding central" );

    return $self->add_repository( 
        'http://repo.maven.apache.org/maven2', @args );
}

sub _artifact_not_found {
    my ($self, $options) = @_;
    my @options_entries = ();
    foreach my $key ( keys( %$options ) ) {
        if ( $options->{$key} ) {
            push( @options_entries, "$key=>$options->{$key}" );
        }
    }
    
    return 'artifact not found for {' 
        . join( '', @options_entries )
        . '}';
}

sub add_local {
    my ($self, $local_repository_path, @args) = @_;
    $logger->debug( "adding local" );

    push( @{$self->{repositories}}, 
        Maven::LocalRepository->new( 
            $local_repository_path, @args ) );

    return $self;
}

sub add_repository {
    my ($self, $url, @args) = @_;
    $logger->debug( "adding repo ", $url );

    push( @{$self->{repositories}},
        Maven::RemoteRepository->new( $url, @args ) );

    return $self;
}

sub _init {
    my ($self, @args) = @_;
    $logger->trace( "initializing repositories" );

    $self->{repositories} = [];

    return $self;
}

sub get_repository {
    my ($self, $url) = @_;
    foreach my $repository (@{$self->{repositories}}) {
        if ($repository->contains($url)) {
            return $repository;
        }
    }
    return;
}

sub resolve {
    my ($self, $coordinate_or_artifact, @parts) = @_;

    my $artifact;
    foreach my $repository ( @{$self->{repositories}} ) {
        last if ( $artifact = $repository->resolve( $coordinate_or_artifact, @parts ) );
    }

    return $artifact;
}

sub resolve_or_die {
    my ($self, $coordinate_or_artifact, %parts) = @_;
    my $resolved = resolve($self, $coordinate_or_artifact, %parts);
    croak( _artifact_not_found( $self, \%parts ) ) if ( !$resolved );
    
    return $resolved;
}

1;

__END__
=head1 SYNOPSIS

    # Dont use Repositories directly...  instead:
    use Maven::Agent;
    my $agent = Maven::Agent->new();
    $agent->resolve('javax.servlet:servlet-api:2.5');

=head1 DESCRIPTION

Represents an ordered collection of repositories that can be used to resolve
C<Maven::Artifact>'s.  This class should not be used directly.  Instead you 
should use an C<Maven::Agent>.

=method add_central(agent => $agent, [%options])

Adds L<maven central|http://repo.maven.apache.org/maven2> to the list of
repositories.  Passes all arguments through to C<add_repository>.

=method add_local($local_repository_path)

Add your C<$local_repository_path> to the list of repositories.

=method add_repository($url, agent => $agent, [%options])

Adds C<$url> to the list of repositories.  C<$agent> will be used to connect 
to the repository.  The current options are:

=over 4

=item metadata_filename

The name of the metadata file.  Defaults to 'maven-metadata.xml'.

=back

=method get_repository($url)

Returns the repository that contains C<$url>.

=method resolve($artifact, [%parts])

Will attempt to resolve C<$artifact>.  C<$artifact> can be either an 
instance of L<Maven::Artifact> or a coordinate string of the form
L<groupId:artifactId[:packaging[:classifier]]:version|https://maven.apache.org/pom.html#Maven_Coordinates>
If resolution was successful, a new L<Maven::Artifact> will be returned 
with its C<uri> set.  Otherwise, C<undef> will be returned.  If C<%parts> 
are supplied, their values will be used to override the corresponding values
in C<$artifact> before resolution is attempted.

=method resolve_or_die($artifact, [%parts])

Calls L<resolve|/"resolve($artifact, [%parts])">, and, if resolution was 
successful, the new C<$artifact> will be returned, otherwise, C<croak> will 
be called.

=head1 SEE ALSO
Maven::LwpAgent
Maven::MvnAgent
Maven::Artifact
Maven::Maven

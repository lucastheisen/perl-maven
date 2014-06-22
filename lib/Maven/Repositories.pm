use strict;
use warnings;

package Maven::Repositories;

# ABSTRACT: An ordered collection of repositories from which to resolve artifacts
# PODNAME: Maven::Repositories

use Carp;
use Log::Any;
use Maven::LocalRepository;
use Maven::Repository;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init( @_ );
}

sub add_central {
    my ($self, @args) = @_;
    $logger->debug( "adding central" );

    return $self->add_repository( @args,
        url => 'http://repo.maven.apache.org/maven2' );
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
    my ($self, @args) = @_;
    $logger->debug( "adding local" );

    push( @{$self->{repositories}}, Maven::LocalRepository->new( @args ) );

    return $self;
}

sub add_repository {
    my ($self, @args) = @_;
    $logger->debug( "adding repo" );

    my $repository;
    if ( ref( $args[0] ) eq 'Maven::Repository' ) {
        $repository = $args[0];
    }
    else {
        require Maven::Repository;
        $repository = Maven::Repository->new( @args );
    }
    push( @{$self->{repositories}}, $repository );

    return $self;
}

sub _init {
    my ($self, @args) = @_;
    $logger->trace( "initializing repositories" );

    $self->{repositories} = [];

    return $self;
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

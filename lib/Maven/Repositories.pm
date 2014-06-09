package Maven::Repositories;

use strict;
use warnings;

sub new {
    my ($class, @args) = @_;
    return bless( {}, $class )->_init( @args );
}

sub add_central {
    my ($self, %options) = @_;

    $self->add_repository(
        url => 'http://repo.maven.apache.org/maven2',
        agent => $options{agent}
    );

    return $self;
}

sub add_local {
    my ($self, @args) = @_;

    my $repository;
    if ( @args && ref($args[0]) eq 'Maven::LocalRepository' ) {
        $repository = $args[0];
    }
    else {
        require Maven::LocalRepository;
        $repository = Maven::LocalRepository->new( @args );
    }
    push( @{$self->{repositories}}, $repository );

    return $self;
}

sub add_repository {
    my ($self, @args) = @_;

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

1;

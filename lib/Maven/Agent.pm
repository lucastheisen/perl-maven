use strict;
use warnings;

package Maven::Agent;

# ABSTRACT: A base agent for working with maven
# PODNAME: Maven::Agent

use Carp qw(croak);
use Maven::Maven;

sub new {
    return bless({}, shift)->_init(@_);
}

sub download {
    my ($self, $artifact, %options) = @_;

    if ($self->is_local($artifact)) {
        return $artifact->get_uri()->get_path();
    }

    my $file;
    if ( $options{to} ) {
        $file = $options{to};
        if ( -d $file ) {
            $file = File::Spec->catfile( $file, "$self->{artifactId}." . $self->get_packaging() );
        }
    }

    return $self->_download_remote($artifact, $file);
}

sub _download_remote {
    croak("implement in subclass");
}

sub get_maven { 
    return shift->{maven};
}

sub _init {
    my ($self, %options) = @_;

    $self->{maven} = $options{maven}
        || Maven::Maven->new(%options);

    return $self;
}

sub is_local {
    my ($self, $artifact) = @_;
    my $uri = $artifact->get_uri();
    return ($uri->scheme() =~ /^file$/i 
        && ($uri->host() eq '' || $uri->host() =~ /^localhost$/));
}

sub resolve {
    return shift->{maven}->get_repositories()->resolve(@_);
}

sub resolve_or_die {
    return shift->{maven}->get_repositories()->resolve_or_die(@_);
}

1;

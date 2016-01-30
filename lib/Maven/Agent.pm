use strict;
use warnings;

package Maven::Agent;

# ABSTRACT: A base agent for downloading artifacts
# PODNAME: Maven::Agent

sub new {
    return bless({}, shift)->_init(@_);
}

sub download {
    my ($self, $artifact, %options) = @_;

    my $uri = $artifact->get_uri();
    if ($uri->scheme() =~ /^file$/i 
        && ($uri->host() eq '' || $uri->host() =~ /^localhost$/)) {
        return $uri->get_path();
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

sub get {
    croak("implement in subclass");
}

sub head {
    croak("implement in subclass");
}

1;

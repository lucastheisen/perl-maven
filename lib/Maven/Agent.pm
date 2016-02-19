use strict;
use warnings;

package Maven::Agent;

# ABSTRACT: A base agent for working with maven
# PODNAME: Maven::Agent

use Carp qw(croak);
use File::Copy;
use Maven::Maven;

sub new {
    return bless({}, shift)->_init(@_);
}

sub download {
    my ($self, $artifact, %options) = @_;

    if (!ref($artifact)
        || !$artifact->isa('Maven::Artifact')
        || !$artifact->get_uri()) {
        $artifact = $self->resolve_or_die($artifact);
    }

    if ($self->is_local($artifact)) {
        my $path = $artifact->get_uri()->path();
        if ($options{to} && $options{to} ne $path) {
            copy($path, $options{to});
            $path = $options{to};
        }
        return $path;
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

sub _default_agent {
    my ($self, @options) = @_;
    require LWP::UserAgent;
    my $agent = LWP::UserAgent->new(@options);
    $agent->env_proxy(); # because why not?
    return $agent;
}

sub _download_remote {
    my ($self, $artifact, $file) = @_;

    $file ||= Maven::Agent::DownloadedFile->new();

    $self->{agent}->get($artifact->get_uri(), ':content_file' => "$file");

    return $file;
}

sub get_maven { 
    return shift->{maven};
}

sub _init {
    my ($self, %options) = @_;

    $options{agent} = $self->_default_agent(%options)
        unless ($options{agent});

    $self->{agent} = $options{agent};
    $self->{maven} = Maven::Maven->new(%options);

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

package Maven::Agent::DownloadedFile;

# Wraps a temp file to hold a reference so as to keep the destructor from
# getting called.  It will provide the filename when used as a string.

use overload q{""} => 'filename', fallback => 1;

sub new {
    my $self = bless({}, shift);
    my $file = File::Temp->new();
    
    $self->{handle} = $file;
    $self->{name} = $file->filename();
    
    return $self;
}

sub filename {
    return $_[0]->{name};
}

1;

__END__
=head1 SYNOPSIS

    use Maven::Agent;

    my $agent = Maven::Agent->new();

Or if you need to configure your own LWP

    my $lwp = LWP::UserAgent->new();
    $lwp->env_proxy();
    my $agent = Maven::Agent->new(agent => $lwp);

    my $maybe_artifact = $agent->resolve(
        'javax.servlet:servlet-api:2.5');
    if ($maybe_artifact) {
        # use it
    }

    my $artifact = $agent->resolve_or_die(
        'javax.servlet:servlet-api:2.5');

    my $servlet_api_jar = $agent->download('javax.servlet:servlet-api:2.5');

    $agent->download('javax.servlet:servlet-api:2.5',
        to => '/path/to/some/directory');

=head1 DESCRIPTION

The default agents for working with Maven artifacts.

=constructor new([%options])

Creates a new agent. C<%options> is passed through to 
L<Maven::Maven/new([%options])>.

=method download($artifact, [%options])

Downloads C<$artifact> and returns the path to the downloaded file. The 
current options are:

=over 4

=item to

The path to download the artifact to.  If the path is a directory, the 
download filename will be C<artifactId.packaging>.  Defaults to a temporary
location.  If it is the temporary location, the type of the return value
is actually a blessed object that overrides the C<""> operator so that it
behaves like a string path.  This allows the temporary file to be cleaned 
up when the object goes out of scope.

=back

=method get_maven 

Returns the C<Maven::Maven> object.

=method is_local($artifact)

Returns a truthy value if C<$artifact> is found in the local repository.
This method expects C<$artifact> to have already been resolved.

=method resolve($artifact, [%parts])

Will attempt to resolve C<$artifact>.  C<$artifact> can be either an 
instance of L<Maven::Artifact> or a coordinate string of the form
L<groupId:artifactId[:packaging[:classifier]]:version|https://maven.apache.org/pom.html#Maven_Coordinates>
If resolution was successful, a new L<Maven::Artifact> will be returned 
with its C<uri> set.  Otherwise, C<undef> will be returned.  If C<%parts> 
are supplied, their values will be used to override the corresponding values
in C<$artifact> before resolution is attempted.

=method resolve_or_die($artifact)

Calls L<resolve|/"resolve($artifact, [%parts])">, and, if resolution was 
successful, the new C<$artifact> will be returned, otherwise, C<croak> will 
be called.

=head1 SEE ALSO
Maven::LwpAgent
Maven::MvnAgent
Maven::Artifact
Maven::Maven

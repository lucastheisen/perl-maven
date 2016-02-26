use strict;
use warnings;

package Maven::MvnAgent;

# ABSTRACT: An agent for downloading artifacts using the mvn command
# PODNAME: Maven::MvnAgent

use parent qw(Maven::Agent);

use Carp qw(croak);
use File::Copy qw(copy);
use Log::Any;
use Maven::Command qw(
    mvn_artifact_params
    mvn_command
);

my $logger = Log::Any->get_logger();

sub _artifact_command {
    # [\%maven_options] $artifact @_
    my $self = shift;
    my $maven_options = ref($_[0]) eq 'HASH' ? shift : {};
    my $artifact = shift;

    if (!$artifact->isa('Maven::Artifact')) {
        $artifact = Maven::Artifact->new($artifact);
    }

    if (!$maven_options->{'--settings'}) {
        my $file = $self->{maven}->dot_m2('settings.xml');
        $maven_options->{'--settings'} = $^O eq 'cygwin'
            ? Cygwin::posix_to_win_path($file)
            : $file
    }
    if (!$maven_options->{'--global-settings'}) {
        my $file = $self->{maven}->m2_home('conf', 'settings.xml');
        $maven_options->{'--global-settings'} = $^O eq 'cygwin'
            ? Cygwin::posix_to_win_path($file)
            : $file
    }
    if (!$maven_options->{'-Duser.home'}) {
        my $path = $self->{maven}->get_property('user.home');
        $maven_options->{'-Duser.home'} = $^O eq 'cygwin'
            ? Cygwin::posix_to_win_path($path)
            : $path
    }

    return $self, $maven_options, $artifact, @_;
}

sub deploy {
    # [\%maven_options], $artifact, $file, $repository_id, $repository_url, [%options]
    my ($self, @args) = _artifact_command(@_);
    $self->_run_or_die($self->deploy_command(@args));
}

sub deploy_command {
    # [\%maven_options], $artifact, $file, $repository_id, $repository_url, [%options]
    my ($self, $maven_options, $artifact, $file,$repository_id, $repository_url,  %options) = _artifact_command(@_);

    my $maven_deploy_plugin_version = $options{maven_deploy_plugin_version} || '2.8.2';

    return mvn_command( 
        $maven_options,
        "org.apache.maven.plugins:maven-deploy-plugin:$maven_deploy_plugin_version:deploy-file",
        {
            mvn_artifact_params($artifact),
            file => $^O eq 'cygwin'
                ? Cygwin::posix_to_win_path($file)
                : $file,
            repositoryId => $repository_id,
            url => $repository_url
        });
}

sub _download_remote {
    my ($self, $artifact, $file) = @_;

    my $uri = $self->get($artifact)->get_uri();

    if ($file) {
        copy($uri->path(), $file)
            || croak('failed to copy file $!');
    }
    else {
        $file = $uri->path();
    }

    return $file;
}

sub get {
    # [\%maven_options], $artifact, [%options]
    my ($self, $maven_options, $artifact, %options) = _artifact_command(@_);

    $self->_run_or_die($self->get_command($maven_options, $artifact, %options));

    return $self->resolve_or_die($artifact->get_coordinate());
}

sub get_command {
    # [\%maven_options], $artifact, [%options]
    my ($self, $maven_options, $artifact, %options) = _artifact_command(@_);

    my $maven_dependency_plugin_version = $options{maven_dependency_plugin_version} || '2.10';

    my @repositories = ();
    foreach my $repository (@{$self->{maven}->get_repositories()->get_repositories()}) {
        next if ($repository->isa('Maven::LocalRepository'));
        push(@repositories, $repository->get_url());
    }

    return mvn_command(
        $maven_options,
        "org.apache.maven.plugins:maven-dependency-plugin:$maven_dependency_plugin_version:get",
        {
            mvn_artifact_params($artifact),
            remoteRepositories => join(',', @repositories)
        });
}

sub _init {
    my $self = shift;

    $self->Maven::Agent::_init(@_);

    return $self;
}

sub install {
    # [\%maven_options], $artifact, $file, [%options]
    my ($self, @args) = _artifact_command(@_);
    $self->_run_or_die($self->install_command(@args));
}

sub install_command {
    # [\%maven_options], $artifact, $file, [%options]
    my ($self, $maven_options, $artifact, $file, %options) = _artifact_command(@_);

    my $maven_install_plugin_version = $options{maven_install_plugin_version} || '2.5.2';

    return mvn_command( 
        $maven_options,
        "org.apache.maven.plugins:maven-install-plugin:$maven_install_plugin_version:install-file",
        {
            mvn_artifact_params($artifact),
            file => $^O eq 'cygwin'
                ? Cygwin::posix_to_win_path($file)
                : $file
        });
}

sub _run_or_die {
    my ($self, $command) = @_;

    my $output = `$command`;
    $logger->tracef("%s\n---- STDOUT ----\n%s\n---- END STDOUT ----", $command, $output);

    croak("Command [$command] failed: " . ($? >> 8)) if ($?);
}

1;

__END__
=head1 SYNOPSIS

    use Maven::MvnAgent;

    my $agent = Maven::Agent->new();

Or if you need to configure your own LWP

    my $lwp = LWP::UserAgent->new();
    $lwp->env_proxy();
    my $agent = Maven::MvnAgent->new(agent => $lwp);

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

This agent extends L<Maven::Agent> in order to wrap C<download> with an
C<mvn dependency:get> therby caching the artifact in the local repository
so that later attempts to resolve the artifact will find it there.  It also
adds a couple additional functions to publish to repositories, both local, and
remote.

=constructor new([%options])

Creates a new agent. C<%options> is passed through to 
L<Maven::Maven/new([%options])>.

=method deploy([\%maven_options], $artifact, $file, $repository_id, $repository_url, [%options])

Deploys C<$file> to C<$repository_url> as C<$artifact>.  Generates the command 
from the arguments using C<deploy_command>

=method deploy_command([\%maven_options], $artifact, $file, $repository_id, $repository_url, [%options])

Returns an C<mvn> command string to deploy C<$file> to C<$repository_url>
as C<$artifact>.  C<$repository_id> indicates a server id in the effective 
settings that contains the required credentials for the operation.  
C<%maven_options> and C<%options> are described on 
L<mvn_command|Maven::Command/"mvn_command([\%mvn_options], @goals_and_phases, [\%parameters]">)

=method download($artifact, [%options])

Downloads C<$artifact>, caching a copy in the local repository and returns the
path to the file.  The current options are:

=over 4

=item to

The path to download the artifact to.  If the path is a directory, the 
download filename will be C<artifactId.packaging>.  Defaults to the proper
location in the local repository.

=back

=method get([\%maven_options], $artifact, [%options])

Downloads C<$artifact> to the local repository and returns an 
L<Maven::Artifact> already resolved to its local location.  Generates the
command from the arguments using C<get_command>.

=method get_command([\%maven_options], $artifact, [%options])

Returns an C<mvn> command string to download C<$artifact> to the local
repository.  C<%maven_options> and C<%options> are described on 
L<mvn_command|Maven::Command/"mvn_command([\%mvn_options], @goals_and_phases, [\%parameters]">)

=method get_maven 

Returns the C<Maven::Maven> object.

=method install([\%maven_options], $artifact, $file, [%options])

Installs C<$file> in the local repository as C<$artifact>.  Generates the
command from the arguments using C<install_command>.

=method install_command([\%maven_options], $artifact, $file, [%options])

Returns an C<mvn> command string to install C<$file> in the local repository.  C<%maven_options> and C<%options> 
are described on 
L<mvn_command|Maven::Command/"mvn_command([\%mvn_options], @goals_and_phases, [\%parameters]">)

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
Maven::MvnAgent
Maven::Artifact
Maven::Maven

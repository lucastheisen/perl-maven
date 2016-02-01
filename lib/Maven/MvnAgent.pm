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
    $logger->debug($output);

    croak("Command [$command] failed: " . ($? >> 8)) if ($?);
}

1;

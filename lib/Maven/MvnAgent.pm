use strict;
use warnings;

package Maven::MvnAgent;

# ABSTRACT: An agent for downloading artifacts using the mvn command
# PODNAME: Maven::MvnAgent

use parent qw(Maven::LwpAgent);

use Exporter qw(import);
use Log::Any;

our @EXPORT_OK = qw(
    mvn_command
);

my $logger = Log::Any->get_logger();

sub deploy {
    my ($self, $repository_id, $repository_url, $file, $artifact, %options) = @_;

    if (!$artifact->isa('Maven::Artifact')) {
        $artifact = Maven::Artifact->new($artifact);
    }

    my $maven_deploy_plugin_version = $options{maven_deploy_plugin_version} || '2.8.2';

    $self->{command_runner}->run_or_die(
        mvn_command( 
            ($options{mvn_options} ? $options{mvn_options} : ()),
            "org.apache.maven.plugins:maven-deploy-plugin:$maven_deploy_plugin_version:deploy-file",
            repositoryId => $repository_id,
            url => $repository_url,
            file => $^O eq 'cygwin'
                ? Cygwin::posix_to_win_path( $file )
                : $file,
            groupId => $artifact->get_groupId(),
            artifactId => $artifact->get_artifactId(),
            packaging => $artifact->get_packaging(),
            ($artifact->get_classifier() ? (classifier => $artifact->get_classifier()) : ()),
            version => $artifact->get_version(),
            ($options{goal_options} ? %{$options{goal_options}} : ()),
            ($options{command_options} ? $options{command_options} : ())
        ),
        ($options{command_runner_options} ? $options{command_runner_options} : ())
    );
    return $self->{repositories}->resolve_or_die($artifact->get_coordinate());
}

sub _download_remote {
    my ($self, $artifact, $file) = @_;

    my $uri = $self->get($artifact)->get_uri();

    if ($file) {
        copy($uri->path(), $file})
            || croak('failed to copy file $!');
    }
    else {
        $file = $uri->path();
    }

    return $file;
}

sub get {
    my ($self, $artifact, %options) = @_;

    if (!$artifact->isa('Maven::Artifact') || !$artifact->get_url()) {
        $artifact = $self->{repositories}->resolve_or_die($artifact);
    }

    my $url = $artifact->get_url();
    if (!$options{force_download} && $url =~ /^file:\/\/.*$/) {
        $logger->debug("Resolved to local cache and no force_download option, no need to get");
        return $artifact;
    }

    my $groupId    = $artifact->get_groupId();
    my $artifactId = $artifact->get_artifactId();
    my $version    = $artifact->get_version();
    my $classifier = $artifact->get_classifier();
    my $packaging  = $artifact->get_packaging();

    my $maven_dependency_plugin_version = $options{maven_dependency_plugin_version} || '2.10';

    my @repositories = ();
    foreach my $repository (@{$self->{repositories}->get_repositories()}) {
        next if ($repository->isa('Maven::LocalRepository'));
        push(@repositories, $repository->get_url());
    }

    $self->{command_runner}->run_or_die(
        mvn_command(
            ($options{mvn_options} ? $options{mvn_options} : ()),
            "org.apache.maven.plugins:maven-dependency-plugin:$maven_dependency_plugin_version:get",
            groupId    => $groupId,
            artifactId => $artifactId,
            version    => $version,
            ($classifier ? (classifier => $classifier) : ()),
            ($packaging  ? (packaging  => $packaging)  : ()),
            remoteRepositories => join(',', @repositories),
            ($options{command_options} ? $options{command_options} : ())
        ),
        ($options{command_runner_options} ? $options{command_runner_options} : ())
    );
    return $self->{repositories}->resolve_or_die($artifact->get_coordinate());
}

sub _init {
    my ($self, $repositories, %options) = @_;

    $self->{repositories}   = $repositories;

    return $self;
}

sub install {
    my ($self, $file, $artifact, %options) = @_;

    if (!$artifact->isa('Maven::Artifact')) {
        $artifact = Maven::Artifact->new($artifact);
    }

    my $maven_install_plugin_version = $options{maven_install_plugin_version} || '2.5.2';

    $self->{command_runner}->run_or_die(
        mvn_command( 
            ($options{mvn_options} ? $options{mvn_options} : ()),
            "org.apache.maven.plugins:maven-install-plugin:$maven_install_plugin_version:install-file",
            file => $^O eq 'cygwin'
                ? Cygwin::posix_to_win_path( $file )
                : $file,
            groupId => $artifact->get_groupId(),
            artifactId => $artifact->get_artifactId(),
            packaging => $artifact->get_packaging(),
            ($artifact->get_classifier() ? (classifier => $artifact->get_classifier()) : ()),
            version => $artifact->get_version(),
            ($options{goal_options} ? %{$options{goal_options}} : ())
        ),
        ($options{command_runner_options} ? $options{command_runner_options} : ())
    );
    return $self->{repositories}->resolve_or_die($artifact->get_coordinate());
}

sub mvn_command {
    # [$mvn_options], $goal, [%goal_options]
    my $mvn_options = ref($_[0]) eq 'ARRAY' ? shift : [];
    my $goal = shift;
    my %goal_options = @_;

    my $mvn_options_string = join(' ', '', @$mvn_options);
    my $params_string = join(
        " -D", '',
        map {
            my $value = $goal_options{$_};
            $value =~ s/\\/\\\\/g;
            $value =~ s/"/\\"/g;
            "$_=\"$value\""
        } keys(%goal_options)
    );

    return "mvn$mvn_options_string $goal$params_string";
}

1;

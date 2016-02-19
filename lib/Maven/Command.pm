use strict;
use warnings;

package Maven::Command;

# ABSTRACT: A command builder for mvn
# PODNAME: Maven::Command

use Exporter qw(import);

our @EXPORT_OK = qw(
    mvn_artifact_params
    mvn_command
);

sub _escape_and_quote {
    my ($value) = @_;
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;
    return "\"$value\"";
}

sub mvn_artifact_params {
    my ($artifact) = @_;
    return (
        groupId => $artifact->get_groupId(),
        artifactId => $artifact->get_artifactId(),
        packaging => $artifact->get_packaging(),
        ($artifact->get_classifier() 
            ? (classifier => $artifact->get_classifier()) 
            : ()),
        version => $artifact->get_version());
}

sub mvn_command {
    # [\%mvn_options], @goals_and_phases, [\%parameters]
    my $mvn_options = ref($_[0]) eq 'HASH' ? shift : {};
    my $parameters = ref($_[$#_]) eq 'HASH' ? pop : {};
    my @goals_and_phases = @_;

    my $mvn_options_string = '';
    foreach my $key (sort keys(%$mvn_options)) {
        $mvn_options_string .= " $key";
        my $value = $mvn_options->{$key};
        if (defined($value)) {
            my $separator = ($key =~ /^\-D/) ? '=' : ' ';
            $mvn_options_string .= $separator . _escape_and_quote($value);
        }
    }

    my $params_string = join('',
        map {
            " -D$_=" . _escape_and_quote($parameters->{$_});
        } sort keys(%$parameters)
    );

    return "mvn$mvn_options_string "
        . join(' ', @goals_and_phases)
        . $params_string;
}

1;

__END__
=head1 SYNOPSIS

    use Maven::Command qw(mvn_artifact_params mvn_command);

    # mvn -X package
    my $command = mvn_command({'-X' => undef}, 'package');
    `$command`;

    # mvn --settings "/opt/shared/.m2/settings.xml" dependency:get \
    #     -DgroupId="javax.servlet" \
    #     -DartifactId="servlet-api" \
    #     -Dversion="2.5"
    my $artifact = Maven::Artifact->new('javax.servlet:servlet-api:2.5');
    my $command = mvn_command(
        {'--settings' => "/opt/shared/.m2/settings.xml"}
        'package', 
        mvn_artifact_params($artifact));
    `$command`;

=head1 DESCRIPTION

The base class for agents specifying the minimal interface.  Subclasses
must implement the C<_download_remote> method.

=export_ok mvn_artifact_params($artifact)

Generates a parameter hash from the coordinate values of C<$artifact>.

=export_ok mvn_command([\%mvn_options], @goals_and_phases, [\%parameters])

Builds an C<mvn> command as a string.  C<%mvn_options> can be any supported
option to C<mvn>, C<@goals_and_phases> can be any list of goals or phases to
be executed and C<%parameters> are any parameters that should be supplied
as system properties (typically used to specify parameters to the goals as
needed).

=head1 SEE ALSO
Maven::LwpAgent
Maven::MvnAgent
Maven::Artifact
Maven::Maven

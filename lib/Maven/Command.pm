use strict;
use warnings;

package Maven::Command;

use Exporter qw(import);

our @EXPORT_OK = qw(
    mvn_artifact_params
    mvn_command
    mvn_goal
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

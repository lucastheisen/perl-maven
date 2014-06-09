use strict;
use warnings;

package Maven::Xml::Pom;

use Maven::Xml::Common::Configuration;
use Maven::Xml::Common::Repository;
use Maven::Xml::Pom::BaseBuild;
use Maven::Xml::Pom::Build;
use Maven::Xml::Pom::CiManagement;
use Maven::Xml::Pom::Contributor;
use Maven::Xml::Pom::Dependency;
use Maven::Xml::Pom::DependencyManagement;
use Maven::Xml::Pom::Developer;
use Maven::Xml::Pom::DistributionManagement;
use Maven::Xml::Pom::IssueManagement;
use Maven::Xml::Pom::License;
use Maven::Xml::Pom::MailingList;
use Maven::Xml::Pom::Organization;
use Maven::Xml::Pom::Parent;
use Maven::Xml::Pom::Profile;
use Maven::Xml::Common::Properties;
use Maven::Xml::Pom::Reporting;
use Maven::Xml::Pom::Scm;

use parent qw(Maven::Xml::XmlFile);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(
    artifactId
    build
    dependencies
    dependencyManagement
    description
    developers
    distributionManagement
    ciManagement
    contributors
    groupId
    inceptionYear
    issueManagement
    licenses
    mailingLists
    modelVersion
    modules
    name
    organization
    packaging
    parent
    pluginRepositories
    properties
    profiles
    repositories
    scm
    url
    version
));

sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'contributors' );
    return if ( $name eq 'dependencies' );
    return if ( $name eq 'developers' );
    return if ( $name eq 'licenses' );
    return if ( $name eq 'modules' );
    return if ( $name eq 'mailingLists' );
    return if ( $name eq 'pluginRepositories' );
    return if ( $name eq 'profiles' );
    return if ( $name eq 'project' );
    return if ( $name eq 'repositories' );

    if ( $name eq 'contributor' ) {
        push( @{$self->{contributors}}, $value );
    }
    elsif ( $name eq 'dependency' ) {
        push( @{$self->{dependencies}}, $value );
    }
    elsif ( $name eq 'developer' ) {
        push( @{$self->{developers}}, $value );
    }
    elsif ( $name eq 'license' ) {
        push( @{$self->{licenses}}, $value );
    }
    elsif ( $name eq 'module' ) {
        push( @{$self->{modules}}, $value );
    }
    elsif ( $name eq 'mailingList' ) {
        push( @{$self->{mailingLists}}, $value );
    }
    elsif ( $name eq 'pluginRepository' ) {
        push( @{$self->{pluginRepositories}}, $value );
    }
    elsif ( $name eq 'profile' ) {
        push( @{$self->{profiles}}, $value );
    }
    elsif ( $name eq 'repository' ) {
        push( @{$self->{repositories}}, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'build' ) {
        return Maven::Xml::Pom::Build->new();
    }
    elsif ( $name eq 'ciManagement' ) {
        return Maven::Xml::Pom::CiManagement->new();
    }
    elsif ( $name eq 'contributor' ) {
        return Maven::Xml::Pom::Contributor->new();
    }
    elsif ( $name eq 'dependency' ) {
        return Maven::Xml::Pom::Dependency->new();
    }
    elsif ( $name eq 'developer' ) {
        return Maven::Xml::Pom::Developer->new();
    }
    elsif ( $name eq 'distributionManagement' ) {
        return Maven::Xml::Pom::DistributionManagement->new();
    }
    elsif ( $name eq 'issueManagement' ) {
        return Maven::Xml::Pom::IssueManagement->new();
    }
    elsif ( $name eq 'license' ) {
        return Maven::Xml::Pom::License->new();
    }
    elsif ( $name eq 'mailingList' ) {
        return Maven::Xml::Pom::MailingList->new();
    }
    elsif ( $name eq 'organization' ) {
        return Maven::Xml::Pom::Organization->new();
    }
    elsif ( $name eq 'parent' ) {
        return Maven::Xml::Pom::Parent->new();
    }
    elsif ( $name eq 'pluginRepository' ) {
        return Maven::Xml::Common::Repository->new();
    }
    elsif ( $name eq 'prerequisites' ) {
        return Maven::Xml::Common::Configuration->new();
    }
    elsif ( $name eq 'properties' ) {
        return Maven::Xml::Common::Properties->new();
    }
    elsif ( $name eq 'profile' ) {
        return Maven::Xml::Pom::Profile->new();
    }
    elsif ( $name eq 'reporting' ) {
        return Maven::Xml::Pom::Reporting->new();
    }
    elsif ( $name eq 'repository' ) {
        return Maven::Xml::Common::Repository->new();
    }
    elsif ( $name eq 'scm' ) {
        return Maven::Xml::Pom::Scm->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser( $name );
}

1;

__END__

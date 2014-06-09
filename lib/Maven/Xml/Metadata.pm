use strict;
use warnings;

package Maven::Xml::Metadata;

use parent qw(Maven::Xml::XmlFile);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(groupId artifactId version versioning plugins));
  
sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'metadata' );
    return if ( $name eq 'plugins' );

    if ( $name eq 'plugin' ) {
        push( @{$self->{plugins}}, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'versioning' ) {
        return Maven::Xml::Metadata::Versioning->new()
    }
    if ( $name eq 'plugin' ) {
        return Maven::Xml::Metadata::Plugin->new()
    }
    return $self;
}

package Maven::Xml::Metadata::Versioning;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(lastUpdated latest release snapshot snapshotVersions versions));

sub _add_value {
    my ($self, $name, $value) = @_;

    return if ( $name eq 'versions' );
    return if ( $name eq 'snapshotVersions' );
    
    if ( $name eq 'version' ) {
        push( @{$self->{versions}}, $value );
    }
    elsif ( $name eq 'snapshotVersion' ) {
        push( @{$self->{snapshotVersions}}, $value);
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ($self, $name) = @_;
    if ( $name eq 'snapshot' ) {
        return Maven::Xml::Metadata::Snapshot->new()
    }
    if ( $name eq 'snapshotVersion' ) {
        return Maven::Xml::Metadata::SnapshotVersion->new()
    }
    return $self;
}

package Maven::Xml::Metadata::SnapshotVersion;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(classifier extension value updated));

package Maven::Xml::Metadata::Snapshot;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(timestamp buildNumber localCopy));

package Maven::Xml::Metadata::Plugin;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(name prefix artifactId));

1;

__END__
=head1 SYNOPSIS

  use Maven::Xml::Metadata;
  my $metadata = Maven::Xml::Metadata->new( file => '/path/to/maven-metadata.xml' );

=head1 DESCRIPTION

Implements a parser for 
L<http://maven.apache.org/ref/3.2.1/maven-repository-metadata/repository-metadata.html>


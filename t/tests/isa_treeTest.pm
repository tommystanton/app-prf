package isa_treeTest;

use strict;
use warnings;

use base 'TestBase';

use Test::More;
use Test::Fatal;

use File::Path ();
use File::Basename ();
use File::Spec;

use App::PRF::Command::isa_tree;

sub isa_tree : Test {
    my $self = shift;

    my $command = $self->_build_command(root => $self->_create_root);

    $self->_mkdir('Foo/Bar');
    $self->_mkfile('Foo/Bar/Baz.pm', q/package Foo::Bar::Baz; sub new {} 1;/);

    $self->_mkfile('One.pm', q/package One; sub new {} 1;/);
    $self->_mkfile('Main.pm', q/package Main; use base 'Foo::Bar::Baz'; sub new {} 1;/);
    $self->_mkfile('Main2.pm', q/package Main2; use parent qw(Foo::Bar::Baz); sub new {} 1;/);

    my $output = '';

    open my $stdout, ">&", STDOUT;
    close STDOUT;
    open STDOUT, '>', \$output or die "Failed to capture stdout: $!";

    $command->run($self->{root});

    close STDOUT;
    open STDOUT, ">&", $stdout;
    close $stdout;

    is($output, <<'EOF');
Foo::Bar::Baz
 + Main
 + Main2
One
EOF
}

sub _build_command {
    my $self = shift;

    return App::PRF::Command::isa_tree->new(@_);
}

sub _slurp {
    my $self = shift;
    my ($file) = @_;

    local $/;
    open my $fh, '<', File::Spec->catfile($self->{root}, $file);
    return <$fh>;
}

sub _mkdir {
    my $self = shift;
    my ($dir) = @_;

    File::Path::make_path(File::Spec->catfile($self->{root}, $dir));

    return;
}

sub _mkfile {
    my $self = shift;
    my ($file, $content) = @_;

    open my $fh, '>', File::Spec->catfile($self->{root}, $file);
    print $fh $content;

    return;
}

sub _create_root {
    my $self = shift;

    my $root =
      File::Spec->catfile(File::Basename::dirname(__FILE__), '../isa_tree');
    $self->{root} = $root;

    if (-e $root) {
        if (-d $root) {
            File::Path::remove_tree($root);
        }
        else {
            die 'Smth is wrong';
        }
    }

    mkdir $root;

    return $self->{root};
}

1;

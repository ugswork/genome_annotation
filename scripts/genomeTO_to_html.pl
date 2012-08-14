use Bio::KBase::GenomeAnnotation::Client;
use JSON::XS;

use Getopt::Long;
use strict;
use Data::Dumper;
use Template;

my $input_file;
my $output_file;

my $rc = GetOptions('input=s' 	=> \$input_file,
		    'output=s'  => \$output_file,
		    );

my $usage = "genomeTO_to_html [--in  genome-file] [--output html-file] [< genome-file] [> html-file]";

@ARGV == 0 or die "Usage: $usage\n";

my $in_fh;
if ($input_file)
{
    open($in_fh, "<", $input_file) or die "Cannot open $input_file: $!";
}
else
{
    $in_fh = \*STDIN;
}

my $out_fh;
if ($output_file)
{
    open($out_fh, ">", $output_file) or die "Cannot open $output_file: $!";
}
else
{
    $out_fh = \*STDOUT;
}
my $json = JSON::XS->new;

my $input_genome;
{
    local $/;
    undef $/;
    my $input_genome_txt = <$in_fh>;
    $input_genome = $json->decode($input_genome_txt);
}

my $template = Template->new();

my $g = $input_genome;

my %ftypes;
for my $f (@{$g->{features}})
{
    $ftypes{$f->{type}}++;
}

my $dna_size = 0;
$dna_size += length($_->{dna}) foreach @{$g->{contigs}};

my @features;
for my $f (sort { my $la = $a->{location}->[0];
		  my $lb = $b->{location}->[0];
		  ($la->[0] cmp $lb->[0]) or ($la->[1] <=> $lb->[1] )}
	   @{$g->{features}})
{
    push(@features, { %$f, lstring => join(" ", map { @$_ } @{$f->{location}}) });
}

my $tdata = {
    ncontigs => scalar(@{$g->{contigs}}),
    dna_size => $dna_size,
    type_counts => [ map { { type => $_, count => $ftypes{$_} } } keys %ftypes ],
    features => \@features,
};

#print STDERR Dumper($tdata);

$tdata->{genome} = $g;

$template->process(\*DATA, $tdata);

    

__DATA__
<title>[% genome.scientific_name %]</title>
<h1>[% genome.scientific_name %]</h1>
<table>
<tr><td>ID: </td><td>[% genome.id %]</td></tr>
<tr><td>Domain: </td><td>[% genome.domain %]</td></tr>
<tr><td>Number of contigs: </td><td>[% ncontigs %]</td></tr>
<tr><td>DNA size: </td><td>[% dna_size %]</td></tr>
[% FOR tc IN type_counts %]
<tr><td>Features of type [% tc.type %]:</td><td>[% tc.count %]</td></tr>
[% END %]
</table>
<table border='1'>
<tr>
<th>ID</th>
<th>Type</th>
<th>Contig</th>
<th>Start</th>
<th>Strand</th>
<th>Length</th>
<th>Function</th>
[% FOR f IN features %]
<tr>
<td>[% f.id %]</td>
<td>[% f.type %]</td>
<td>[% f.location.0.0 %]</td>
<td>[% f.location.0.1 %]</td>
<td>[% f.location.0.2 %]</td>
<td>[% f.location.0.3 %]</td>
<td>[% f.function %]</td>
</tr>
[% END %]
</table>



package Setup;

use strict;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(hydra_setup);

sub hydra_setup {
  my ($db) = @_;
  $db->resultset('Users')->create({ username => "root", emailaddress => 'root@email.com', password => '' });
}

sub nrBuildsForJobset {
  my ($jobset) = @_;
  return $jobset->builds->search({},{})->count ;
}

sub nrQueuedBuildsForJobset {
  my ($jobset) = @_;
  return $jobset->builds->search({},{ join => 'schedulingInfo' })->count ;
}

sub createBaseJobset {
  my ($jobsetName, $nixexprpath) = @_;
  my $project = $db->resultset('Projects')->update_or_create({name => "tests", displayname => "", owner => "root"});
  my $jobset = $project->jobsets->create({name => $jobsetName, nixexprinput => "jobs", nixexprpath => $nixexprpath, emailoverride => ""});

  my $jobsetinput;
  my $jobsetinputals;

  $jobsetinput = $jobset->jobsetinputs->create({name => "jobs", type => "path"});
  $jobsetinputals = $jobsetinput->jobsetinputalts->create({altnr => 0, value => getcwd."/jobs"});

  return $jobset;
}

sub createJobsetWithOneInput {
  my ($jobsetName, $nixexprpath, $name, $type, $uri) = @_;
  my $jobset = createBaseJobset($jobsetName, $nixexprpath);

  my $jobsetinput;
  my $jobsetinputals;

  $jobsetinput = $jobset->jobsetinputs->create({name => $name, type => $type});
  $jobsetinputals = $jobsetinput->jobsetinputalts->create({altnr => 1, value => $uri});

  return $jobset;
}

sub evalSucceeds {
  my ($jobset) = @_;
  my $res = captureStdoutStderr(60, ("../src/script/hydra_evaluator.pl", $jobset->project->name, $jobset->name));
  print STDERR "Evaluation errors for jobset ".$jobset->project->name.":".$jobset->name.": \n".$jobset->errormsg."\n" if $jobset->errormsg;
  return $res;
}

1;

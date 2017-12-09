#!/usr/bin/perl
use strict;
use warnings;
use local::lib;
use feature 'say';
use LWP::Simple;
my $site = "https://santafe.craigslist.org/search/acc";

# Reduce all URLs to standard format
sub standardize_urls {
	my $source = $_[0];
	my $canon = "";
	return ($canon) if ($source =~ /^(mailto:|telnet:|callto:)/);
	if($source=~ /^\//) {
		$source = $site . $source;
	}
	$source =~ s/[\#?].*//;
	return $source;
}

# Craigslist filter
sub filterCraigslist{
	my @urls = @_;
	my @goodness;
	my $re = "\.html";
	for my $url(@urls){
		if($url =~ /$re/){
			push(@goodness, $url);
		}
	}
	return @goodness;
}

# Get outward facing links that may appear interesting
sub getLinks{
	my $html;
	my @inputs=@_;
	my @urls;

	# Grab a web page and check the links 
	foreach my $page(@inputs){
		print "Checking $page\n";
		$html = get($page);
		@urls = $html =~ /\shref="?([^\s>"]+)/gi;
	}

	my %counter;
	my @externals = ();
	my $full;

	# Remove sites that start with the same url as the input
	foreach my $url(@urls){
		$full = standardize_urls($url);
		next unless($full);
		
		if($full !~ /^$site/) {
			push @externals, $full;
			$counter{$full}++;
		}
	}

	# Print and return urls
	my @interesting_urls;
	print "Websites found on @inputs\n";
	foreach my $url(keys %counter){
		#print "$url\n";
		push(@interesting_urls, $url);
	}
	return @interesting_urls;
}


# Uses ssmtp to send an email
sub sendEmail{
	
	# Args 
	my ($destination, $subject, $body) = @_;

	say $destination;
	say $subject;
	say $body;
	#$body = "body";
	my $command="echo \'$body\' | mail -s \'$subject\' $destination";
	say "\nExecuting shell command: $command";
	my $output = qx($command);
	# Blocking email send, use fork/exec for non-blocking behavior
	#system("sh", @arguments);
	
}

# Main execution
my $search_url =  "https://santafe.craigslist.org/search/acc";
#my $response = getHtmlPage($url); 
#say $response;


# Prevent duplicate sends by storing sent jobs in file
my $filename = ".sent_jobs";
my $handle = undef;
open($handle, "<", $filename) or say "No jobs have been stored in $filename yet. Will generate this file if jobs are found.\n";

# Search given website for interesting urls
my @potential_opportunities = filterCraigslist(getLinks(($search_url)));
my $url = $potential_opportunities[0];

say "html from the first site";
say get($url);
sendEmail('holmanb0214@my.uwstout.edu', "Found a job!", $url);


# Inside of the ul class="rows", I need to pick up all of the href links in <li class="result-row">
# These links should be stored in an array and then subsequently checked to see if they match the requirements
#
#<ul class="rows">
#<li class="result-row" data-pid="6396807405" data-repost-of="4812601538">


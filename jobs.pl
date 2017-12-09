#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use YAML::Tiny;
use local::lib;
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
		print "$url\n";
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

# does a keyword search based on a hash of keywords passed in 
sub keyword_search{

}

# Open the config
my $yaml = YAML::Tiny->read('.config.yml');	

# Get a reference to the first document
my $config = $yaml->[0];

my $search_url =  "https://santafe.craigslist.org/search/acc";

# Loop through config  
while (my($person_key, $person_value) = each %$config){
 	say "Searching for jobs for  $person_value->{name}";	
	
	my $found_jobs;

	# Search each profile
	my $profiles = $person_value->{profiles};
	while (my($key, $profile_value) = each %$profiles){
		
		#say "key: $key value: $profile_value urls: $profile_value->{location_urls}[0]";
		my @locations = $profile_value->{location_urls};
		for(my $j=0;$j<scalar(@locations);$j++){
			my $config_urls = $profile_value->{location_urls}[$j];
			say "Searching $config_urls";
			#my $response = getHtmlPage($url); 

			# Search given website for interesting urls
			my @potential_opportunities = filterCraigslist(getLinks($config_urls));

			my $url = $potential_opportunities[0];
#
#			say "html from the first site";
			say get($url);
		}		
 	}	
	# Sending emails
	my @emails=$person_value->{email};
	for(my $i=0;$i<scalar(@emails);$i++){
		
		say "Sending emails to $person_value->{email}[$i]";
		#sendEmail($person_value->{email}[$i], "Found a job!", $search_url);
	}
}


#say "config: $config->{person}{profiles}{profile}{location_urls}[0]";

# Main execution
#my $search_url =  "https://santafe.craigslist.org/search/acc";
#my $response = getHtmlPage($url); 
#say $response;
#say $person->{name};

# Prevent duplicate sends by storing sent jobs in file
#my $filename = ".sent_jobs";
#my $handle = undef;
#open($handle, "<", $filename) or say "No jobs have been stored in $filename yet. Will generate this file if jobs are found.\n";

# Search given website for interesting urls
#my @potential_opportunities = filterCraigslist(getLinks(($config->{person}{profiles}{profile}{location_urls}[0])));
#my $url = $potential_opportunities[0];

#say "html from the first site";
#say get($url);





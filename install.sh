#!/bin/bash

# This is a prototype installer for getting a new user started with minimal systems.
# This will be tested on Debian-like systems. If this doesn't work, please open a 
# ticket on Github.

echo "starting install...";
# Installing and setting up cpanm, a perl package manager
cpan App::cpanminus;

# Telling bash and local::lib where to find the dependencies
cpanm local::lib;
echo 'eval "$(perl -I$HOME/foo/lib/perl5 -Mlocal::lib=$HOME/foo)"' >>~/.bashrc

# Installing the perl dependencies
cpanm install YAML::Tiny;
cpanm install LWP::Simple;
cpanm install Getopt::Long; 

# Install ssmtp
apt-get install ssmtp -y
apt-get install mailutils

# Add the local directory to the path temporarily
export PATH=$PATH:.

# Copy the file in the usr bin for running permanently
# This is pretty standard on debian systems methinks
cp gigfinder.pl gigfinder
chmod 754 gigfinder.pl
chmod 754 gigfinder
mkdir ~/bin
mv gigfinder ~/bin


echo "Attempting dry-run to validate install";
dryrun=$(perl gigfinder.pl -d)
echo $dryrun
echo 'If this succeeded, you should be able to run $gigfinder.pl -h for more details';

# Instructions to user
echo "Congratulations!!! You are almost there.";
echo "You need to configure ssmtp to be able to send email";
echo "edit the file /etc/ssmtp/ssmtp.conf";
echo "see http://www.raspberry-projects.com/pi/software_utilities/email/ssmtp-to-send-emails for more details";
echo "the syntax below should work:";
echo "echo \"Hello world email body\" | mail -s \"Test Subject\" recipientname@domain.com";

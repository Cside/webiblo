#!/usr/bin/env perl

use 5.10.0;
use strict;
use warnings;
use JSON::XS qw(encode_json);
use Web::Query qw(wq);
use URI;
use Digest::MD5 qw(md5_hex);
use JSON::Syck;
use LWP::Simple;

my $url = 'http://www.paulgraham.com/articles.html';
my $meta = {
    title => 'Essays - Paul Graham',
    author => 'Paul Graham',
    cover_image => 'http://a3.mzstatic.com/us/r1000/018/Purple/01/f0/26/mzl.juizrdbz.320x480-75.jpg',
    content_xpath => '//table//table[1]',
    #exclude_xpath => '/html[1]/body[1]/table[1]/tbody[1]/tr[1]/td[1]',
    chapters => [reverse @{
        wq($url)
        ->find('table table:nth-of-type(2) tr[valign="top"]')
        ->filter(sub {
          $_->find('a')->first->attr('href') !~ /acl[12]/;
        })
        ->map(sub {
            my $entry_url = URI->new_abs($_->find('a')->first->attr('href'), $url)->as_string;
            +{
                title => sprintf("(%d) %s", get_delicious_bookmark_count($entry_url), $_->text),
                uri => $entry_url,
            }
        })
    }],
};

my $json = JSON::XS->new;
$json->indent(1);
print $json->encode($meta);

sub get_delicious_bookmark_count {
    $url = shift;
    my $json = LWP::Simple::get("http://feeds.delicious.com/v2/json/urlinfo/" . md5_hex($url));
    my $data = JSON::Syck::Load($json);
    return $data->[0]->{total_posts} || 0;
}


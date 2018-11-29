#!perl -w
use strict;
use Test::More;

use Imager::File::WEBP;
use Imager::Test qw(test_image is_image_similar);
use lib 't/lib';
use TestImage qw(alpha_test_image);

my $im = Imager->new;

{
  my @im = Imager->read_multi(file => "testimg/simple.webp", type => "webp");
  is(@im, 1, "read single image (using multi interface)");
  is_image_similar($im[0], test_image(), 2_000_000, "check for close match");
  my ($format) = $im[0]->tags(name=>'i_format');
  is($format, 'webp', "check i_format tag");
  my ($mode) = $im[0]->tags(name => 'webp_mode');
  is($mode, 'lossy', "check webp_mode tag");
}

{
  my @im = Imager->read_multi(file => "testimg/lossless.webp", type => "webp");
  is(@im, 1, "read single lossless image (using multi interface)");
  my ($format) = $im[0]->tags(name=>'i_format');
  is($format, 'webp', "check i_format tag");
  my ($mode) = $im[0]->tags(name => 'webp_mode');
  is($mode, 'lossless', "check webp_mode tag");
}

{
  my @im = Imager->read_multi(file => "testimg/simpalpha.webp", type => "webp");
  is(@im, 1, "read single alpha image (using multi interface)");
  my $check = alpha_test_image();
  is_image_similar($im[0], $check, 2_000_000, "check for close match");
}

{
  my @im = Imager->read_multi(file => "testimg/anim.webp", type => "webp");
  is(@im, 2, "read 2 images with multi interface");
  is_image_similar($im[0], test_image(), 2_000_000, "check for close match");
  is_image_similar($im[1], alpha_test_image(), 2_000_000, "check for close match");

  is($im[0]->tags(name => "webp_left"), 0, "first frame left");
  is($im[1]->tags(name => "webp_left"), 20, "second frame left");
  is($im[0]->tags(name => "webp_top"), 0, "first frame top");
  is($im[1]->tags(name => "webp_top"), 30, "second frame top");
  is($im[0]->tags(name => "webp_loop_count"), 0, "first loop count");
  is($im[1]->tags(name => "webp_loop_count"), 0, "second loop count");
  is($im[0]->tags(name => "webp_background"), "color(255,255,255,255)",
     "first background");
  is($im[1]->tags(name => "webp_background"), "color(255,255,255,255)",
     "second background");
  is($im[0]->tags(name => "webp_duration"), 200, "first image duration");
  is($im[1]->tags(name => "webp_duration"), 300, "second image duration");
}

SKIP:
{
  my $im = Imager->new;
  ok($im->read(file => "testimg/simple.webp", type => "webp"),
     "read simple using single interface")
    or skip("No image read", 1);
  is_image_similar($im, test_image(), 2_000_000, "check for close match");
}

SKIP:
{
  my $im = Imager->new;
  ok($im->read(file => "testimg/anim.webp", type => "webp", page => 1),
     "read anim second image using single interface")
    or skip("No image read", 1);
  is_image_similar($im, alpha_test_image(), 2_000_000, "check for close match");
}

{
  my $im = Imager->new;
  open my $fh, "<:raw", "testimg/simple.webp"
    or die;
  my $data = do { local $/; <$fh> };
  my $bad = $data;
  substr($bad, -100) = ''; # truncate it
  print "# ", length $data, "\n";
  print "# ", length $bad, "\n";
  ok(!$im->read(data => \$bad, type => "webp"),
     "fail to read truncated file");
  print "# ", $im->errstr, "\n";
  $im->write(file => "bad.png");
}

{
  Imager->set_file_limits(width => 100, height => 100);
  ok(!$im->read(file => "testimg/simple.webp"),
     "fail to read too large an image");
  like($im->errstr, qr/image width/, "check message");
}
Imager->set_file_limits(reset => 1);

done_testing();

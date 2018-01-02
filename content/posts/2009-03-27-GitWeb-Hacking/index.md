---
title: GitWeb Hacking.
author: Dataforce
type: post
date: 2009-03-27T02:52:27+00:00
url: /2009/03/GitWeb-Hacking/
category:
  - Code
  - General

---
Recently I setup gitweb on one of my servers to allow a web-based frontend to any git projects which the users of the server place in their ~/git/ directory.

After playing about with it, I noticed that it allowed for placing a README.html file in the git config directory to allow extra info to be shown on the summary view, managed to get it to pull the README.html file from the actual repository itself, and not the config directory, thus allowing the README.html to be versioned along with everything else, and not require the user to edit it on the server, but rather just edit it locally and push it.

This is a simple change in `/usr/lib/cgi-bin/gitweb.cgi`:

From (line 3916 or so):

{{< prettify perl >}}
	if (-s "$projectroot/$project/README.html") {
		if (open my $fd, "$projectroot/$project/README.html") {
			print "<div class=\"title\">readme</div>\n" .
			      "<div class=\"readme\">\n";
			print $_ while (<$fd>);
			print "\n</div>\n"; # class="readme"
			close $fd;
		}
	}
{{< /prettify >}}

To:

{{< prettify >}}
if (my $readme_base = $hash_base || git_get_head_hash($project)) {
		if (my $readme_hash = git_get_hash_by_path($readme_base, "README.html", "blob")) {
			if (open my $fd, "-|", git_cmd(), "cat-file", "blob", $readme_hash) {
				print "<div class=\"title\">readme</div>\n";
				print "<div class=\"readme\">\n";

				print <$fd>;
				close $fd;
				print "\n</div>\n";
			}
		}
	}
{{< /prettify >}}

I also added a second slightly hack that uses google's code prettyfier when displaying a file, and makes the line numbers separate from the code so they don't copy also when you copy the code,

From (line 2476 or so):

{{< prettify perl >}}
print "</head>\n" .
              "<body>\n";

{{< /prettify >}}

To:

{{< prettify perl >}}
print qq(<link href="http://google-code-prettify.googlecode.com/svn/trunk/src/prettify.css" type="text/css" rel="stylesheet" />\n);
        print qq(<script src="http://google-code-prettify.googlecode.com/svn/trunk/src/prettify.js" type="text/javascript"></script>\n);

        print "</head>\n" .
              "<body onload=\"prettyPrint()\">\n";
{{< /prettify >}}

and

From (line 4351 or so):

{{< prettify perl >}}
while (my $line = <$fd>) {
		chomp $line;
		$nr++;
		$line = untabify($line);
		printf "<div class=\"pre\"><a id=\"l%i\" href=\"#l%i\" class=\"linenr\">%4i</a> %s</div>\n",
		       $nr, $nr, $nr, esc_html($line, -nbsp=>1);
	}
{{< /prettify >}}

To:

{{< prettify >}}
print "<table><tr><td class=\"numbers\"><pre>";
	while (my $line = <$fd>) {
		chomp $line;
		$nr++;
		printf "<a id=\"l%i\" href=\"#l%i\" class=\"linenr\">%4i</a>\n", $nr, $nr, $nr;
	}
	print "</pre></td>";
	open my $fd2, "-|", git_cmd(), "cat-file", "blob", $hash;
	print "<td class=\"lines\"><pre class=\"prettyprints\">";
	while (my $line = <$fd2>) {
		chomp $line;
		$line = untabify($line);
		printf "%s\n", esc_html($line, -nbsp=>1)
	}
	print "</pre></td></tr></table>";
	close $fd2;
{{< /prettify >}}

This could do with a quick clean up (reuse $fd rather than opening $fd2) but it works.

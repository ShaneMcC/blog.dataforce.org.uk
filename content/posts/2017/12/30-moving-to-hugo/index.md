---
title: Moving to Hugo
author: Dataforce
url:  /2017/12/moving-to-hugo/
image: blog-screenshot.png
description: I recently moved this blog to Hugo, this is how I did it. Kind of.
type: post
date: 2017-12-30T04:56:26Z
category:
  - General
---

For a while now I've been thinking of moving this blog to a statically generated site rather than using wordpress.

There are a number of reasons for this:

  1. I can version-control the content rather than relying on wordpress database backups.
  2. It renders quicker
  3. I don't actually use any of the wordpress features, so it's just bloat, and a potential security hole.

I've seen [Chris](https://chameth.com/) successfully use [Hugo](https://gohugo.io/) for his site and it seems to do exactly what I want, So I took the opportunity during the Christmas break to spend some time converting my blog from Wordpress to Hugo.

Actually doing this was a multi-stage process.

<!--more-->

### Stage 1 - Exporting the old content

This was mostly achieved using the [wordpress-to-hugo-exporter](https://github.com/SchumacherFM/wordpress-to-hugo-exporter).

Once the content was exported, I then went through and removed any posts that were not marked as `Published` (This blog has technically been running for a long time under various guises. Some of the very old content is "my-first-blog" style garbage and over the years I've marked these as not-published within wordpress. I'll keep hold of these posts separately from the main site git repository.).

### Stage 2 - Converting the theme

The next stage was converting the old wordpress theme I was using. It took me a long time to decide on a theme that I even somewhat liked before, so for now I figured I'd keep the same theme.

Thankfully hugo themes are pretty straight forward and the conversion process was pretty painless once I got to grips with the hugo syntax.

### Stage 3 - Fixing the exported content

The [wordpress-to-hugo-exporter](https://github.com/SchumacherFM/wordpress-to-hugo-exporter) plugin did a pretty decent job of exporting the old content, but not perfect.

When exporting, the content gets run through the wordpress `the_content` filter so that 3rd party plugin get a chance to modify it. Sometimes the generated HTML confused the converter and resulted in sub-optimal (broken) markdown output.

Thankfully, I don't have a huge amount of content, and hugo lets you run a debugging server using `hugo server` that automatically refreshes pages as you save them, this allowed me to fix the content and see the fixes in real time.

### Stage 4 - Publishing

This was the easy stage. I created a [new github repo](http://github.com/shanemcc/blog.dataforce.org.uk) that stores the site content.

This is then checked out on the webserver and `hugo` is run in the directory to generate the final content into the `/public` directory that is then served by my webserver.

To automate the deployments process, there is also a script in there (`github-webhook-deploy.php`) that I run on the server under a different domain that gets poked by github any time I push the repo, this script handles pulling the updated version of the site and running `hugo` on it.

### Final Thoughts

 - Hugo's theming is nice and simple so at some point I may redo the theme. The content is totally agnostic to the theme, so this should be pretty seamless.

 - The new blog no longer has comments. I don't think this is a big loss, there are plenty of ways for people to contact me. I may look into something like disqus or so in future.

 - I don't know if this will actually make me more likely to update the site or write more, but it's worth a try.

 - Sorry to RSS Readers, the change is likely going to spam you about all the posts again.

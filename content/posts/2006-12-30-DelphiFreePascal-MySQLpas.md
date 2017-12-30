---
title: Delphi/FreePascal MySQL.pas
author: Dataforce
type: post
date: 2006-12-30T14:00:23+00:00
url: /2006/12/DelphiFreePascal-MySQLpas/
category:
  - General

---
Due to a recent need in a project of mine for mySQL access from delphi/freepascal I have adapted the version of mysql.pas from <http://www.fichtner.net/delphi/mysql.delphi.phtml> to load both libmysql.dll (on svn) and libmysqlclient.so (Usually located in /usr/lib/mysql/).

I also created a wrapper class for it (TSQL in SQL.pas)

Downloads can be found here: [http://blog.dataforce.org.uk/viewcvs/misc/MySQL/]

Any queries/questions should be left in the comments.

(This has been tested, and compiled on Freepascal on Linux (1.9.8) and windows (2.0.0) and in Delphi (6/7/Turbo) on windows.)

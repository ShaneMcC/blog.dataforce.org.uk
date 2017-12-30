---
title: {{ replace .TranslationBaseName "-" " " | title }}
author: Dataforce
url:  {{ dateFormat "/2006/01" .Date }}/{{ .TranslationBaseName }}/
image:
description:
draft: true
type: post
date: {{ .Date }}
category:
  - General
---


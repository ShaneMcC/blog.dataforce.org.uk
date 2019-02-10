<?php
	/**
	 * GIT DEPLOYMENT SCRIPT.
	 *
	 * Used for automatically deploying websites via github or bitbucket, more deets here:
	 *
	 * Based on https://gist.github.com/1809044
	 */

	$config['verbosechannel'] = '';
	$config['reportchannel'] = '';

	if (file_exists(dirname(__FILE__) . '/report.functions.php')) {
		require_once(dirname(__FILE__) . '/report.functions.php');
	}
	if (!function_exists('reportSoren')) {
		function reportSoren($message, $channel = array()) { }
	}

	$sitename = 'blog.dataforce.org.uk';

	$hostname = `hostname -f`;
	reportSoren("\002[$sitename]\002 Beginning deployment on $hostname", [$config['verbosechannel']]);
	chdir('/var/www/' . $sitename . '/');

	$branch = 'master';

	// The commands
	$commands = array(
		'echo $PWD',
		'whoami',
		'git fetch',
		'git reset --hard origin/' . $branch,
		'git submodule sync',
		'git submodule update --init',
	);

	$afterCommands = array(
		'build.sh',
	);

	// Run the commands for output
	function runCommands($commands, $output = '') {
		$success = true;
		foreach($commands AS $command){
			// Get the command and the return code
			$wantedCode = 0;
			if (is_array($command)) {
				$wantedCode = isset($command[1]) ? $command[1] : 0;
				$command = $command[0];
			}

			// Run the command
			$tmp = array();
			$return = 0;
			exec($command . ' 2>&1', $tmp, $return);
			$tmp = implode("\n", $tmp);

			// Check that the return code is what we wanted.
			if (is_array($wantedCode) && !in_array($return, $wantedCode)) { $success = false; }
			else if (!is_array($wantedCode) && $return != $wantedCode) { $success = false; }

			// Output
			$output .= "<span style=\"color: #6BE234;\">\$</span> <span style=\"color: #729FCF;\">{$command}</span> [$return]\n";
			$output .= ansispan(htmlentities($tmp)) . "\n";
		}

		return array($success, $output);
	}

	list($success, $output) = runCommands($commands);

	if ($success) {
		reportSoren("\002\0033[$sitename]\003\002 Successful deployment on $hostname", [$config['verbosechannel']]);
	} else {
		reportSoren("\002\0034[$sitename]\003\002 Failed deployment on $hostname", [$config['verbosechannel']]);
	}
	$state = `git log -1 --pretty=oneline`;
	reportSoren("\002[$sitename]\002 Repo at: $state", [$config['verbosechannel']]);

	list($success, $output) = runCommands($afterCommands, $output);

	if ($success) {
		reportSoren("\002\0033[$sitename]\003\002 Successful build on $hostname", [$config['verbosechannel'], $config['reportchannel']]);
		reportSoren("\002[$sitename]\002 Repo at: $state", [$config['reportchannel']]);
	} else {
		reportSoren("\002\0034[$sitename]\003\002 Failed build on $hostname", [$config['verbosechannel'], $config['reportchannel']]);
	}

	// Make it pretty for manual user access (and why not?)
?>
<!DOCTYPE HTML>
<html lang="en-US">
<head>
	<meta charset="UTF-8">
	<title>GIT DEPLOYMENT SCRIPT</title>
</head>
<body style="background-color: #000000; color: #FFFFFF; font-weight: bold; padding: 0 10px;">
<pre>
 .  ____  .    ____________________________
 |/      \|   |	                           |
[| <span style="color: #FF0000;">&hearts;    &hearts;</span> |]  | Git Deployment Script v0.1 |
 |___==___|  /        &copy; oodavid 2012       |
	      |____________________________|

<?php echo $output; ?>
</pre>
</body>
</html>
<?php

		/* FROM: https://github.com/Alanaktion/ansispan-php/blob/master/ansispan.inc.php */
		/* (Modified a bit because shell_exec removes the control codes.) */
		// Parses text with ANSI control codes and returns HTML
		function ansispan($str) {
			// Colors
			$fgColors = array(
				30 => 'black',
				31 => 'red',
				32 => 'green',
				33 => 'yellow',
				34 => 'blue',
				35 => 'magenta',
				36 => 'cyan',
				37 => 'white'
			);
			$bgColors = array(
				40 => 'black',
				41 => 'red',
				42 => 'green',
				43 => 'yellow',
				44 => 'blue',
				45 => 'magenta',
				46 => 'cyan',
				47 => 'white'
			);

			// Replace foreground color codes
			foreach(array_keys($fgColors) as $color) {
				$span = '<span style="color: '.$fgColors[$color].'">';

				// 3[Xm == 3[0;Xm sets foreground color to X
				$str = preg_replace("/\[".$color.'m/',$span,$str);
				$str = preg_replace("/\[0;".$color.'m/',$span,$str);
			}

			// Replace background color codes
			foreach(array_keys($fgColors) as $color) {
				$span = '<span style="background-color: '.$fgColors[$color].'">';

				// 3[Xm == 3[0;Xm sets background color to X
				$str = preg_replace("/\[".$color.'m/',$span,$str);
				$str = preg_replace("/\[0;".$color.'m/',$span,$str);
			}

			// 3[1m enables bold font, 3[22m disables it
			$str = preg_replace("/\[1m/",'<b>',$str);
			$str = preg_replace("/\[22m/",'</b>',$str);

			// 3[3m enables italics font, 3[23m disables it
			$str = preg_replace("/\[3m/",'<i>',$str);
			$str = preg_replace("/\x1B33\[23m/",'</i>',$str);

			// Catch any remaining close tags
			$str = preg_replace("/\[m/",'</span>',$str);
			$str = preg_replace("/\[0m/",'</span>',$str);

			// Replace "default" codes with closing span
			return preg_replace("/\[(39|49)m/",'</span>', $str);
		}

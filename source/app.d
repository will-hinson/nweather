import std.logger;
import std.stdio;
import std.string : toUpper;

import d2sqlite3;
import requests;

import source.nweather.actions;
import source.nweather.caching.actions;
import source.nweather.models.cacheupdate;

// temp
import core.stdc.stdlib : exit;

void main(string[] args)
{
	// update the target location cache
	updateCache();

	// determine what location the user requested
	if (args.length < 2)
	{
		writeln("usage: " ~ args[0] ~ " [station]");
		exit(1);
	}

	args[1].fetchWeatherForLocation();
}

module source.nweather.actions;

import std.algorithm.comparison : levenshteinDistance;
import std.algorithm.mutation : SwapStrategy;
import std.algorithm.searching : count;
import std.algorithm.setops : setIntersection, SetIntersection;
import std.algorithm.sorting : sort;
import std.string : replace, toUpper;

import dxml.dom;
import requests;

import source.nweather.caching.database;
import source.nweather.models.target;

// temp
import std.stdio;
import source.nweather.caching.actions;

struct Similarity
{
    float overlapCoeff;
    Target target;
}

void fetchWeatherForLocation(string location)
{
    // get a list of known targets
    auto db = getCacheDatabase();
    auto results = db.getKnownTargets();

    // get similarity coefficients for all of the known names
    Similarity[] similarities;
    char[] locationArr = location.replace(" ", "").dup;
    sort(cast(ubyte[]) locationArr);
    foreach (target; results)
    {
        char[] targetArr = target.targetName.replace(" ", "").dup;
        sort(cast(ubyte[]) targetArr);

        long shortestLength = (
            locationArr.length < targetArr.length ?
                locationArr.length : targetArr.length
        );

        auto intersection = setIntersection(locationArr, targetArr);
        int intersectionLength = 0;
        while (!intersection.empty)
        {
            intersection.popFront();
            intersectionLength++;
        }
        similarities ~= Similarity(
            (cast(float) intersectionLength) / (cast(float) shortestLength),
            target
        );
    }
    similarities.sort!("a.overlapCoeff > b.overlapCoeff");

    // get the url of the target xml resource
    string targetUrl;
    if (location.length > 4 && similarities[0].overlapCoeff > 0.85)
    targetUrl = similarities[0].target.targetUrl;
    else
        targetUrl = "https://w1.weather.gov/xml/current_obs/" ~ location ~ ".xml";

    // get the response data from the remote target
    Request request = Request();
    Response response = request.get(targetUrl);
    if (response.code != 200)
    {
        writeln("nweather: Unable to fetch weather data for location '", location, "'");
        writeln("nweather: Target URL was '" ~ targetUrl ~ "', response code was ", response.code);
        return;
    }

    // parse the response body for a list of localities
    string[string] data;
    auto document = parseDOM(cast(string) response.responseBody);
    if (document.children[1].name != "current_observation")
    {
        writeln("nweather: Unable to fetch weather data for location '", location, "'");
        writeln("nweather: Target URL was '" ~ targetUrl ~ "', <current_observation> tag was missing");
        return;
    }
    foreach (element; document.children[1].children)
    {
        // exclude any elements with multiple child elements
        if (element.children.length != 1)
            continue;

        data[element.name] = element.children[0].text;
    }

    write("Station ", data["station_id"], " | ");
    writeln(data["location"]);
    writeln("==================================================================");
    writeln("As of ", data["observation_time_rfc822"]);
    writeln();
    writeln("Temperature:     ", data["temperature_string"]);
    if ("weather" in data)
        writeln("Conditions:      ", data["weather"]);
    if ("wind_mph" in data)
    {
        if ("wind_gust_mph" in data)
            writeln("Wind:            ", data["wind_mph"], " MPH ", data["wind_dir"], " ", data["wind_degrees"],
        "° (Gusts to ", data["wind_gust_mph"], " MPH)");
    else
            writeln("Wind:            ", data["wind_mph"], " MPH ", data["wind_dir"], " ", data["wind_degrees"], "°");
    }
    writeln("Pressure:        ", data["pressure_in"], " inHg");
    writeln("Rel. humidity:   ", data["relative_humidity"], "%");
    writeln("Dewpoint:        ", data["dewpoint_f"], "F (", data["dewpoint_c"], "C)");
    writeln();
    writeln("Long./Lat.:      ", data["longitude"], ", ", data["latitude"]);
    if ("visibility_mi" in data)
        writeln("Visibility:      ", data["visibility_mi"], " mi.");
    writeln("\n");
    writeln("(Credit: " ~ data["credit"] ~ ")");
}

module source.nweather.actions;

import std.algorithm.comparison : levenshteinDistance;
import std.algorithm.sorting : sort;
import std.string : toUpper;

import dxml.dom;
import requests;

import source.nweather.caching.database;
import source.nweather.models.target;

// temp
import std.stdio;
import source.nweather.caching.actions;

struct EditDistance
{
    float distance;
    Target target;
}

void fetchWeatherForLocation(string location)
{
    // get a list of known targets
    auto db = getCacheDatabase();
    auto results = db.getKnownTargets();

    // get edit distances for all of the known names
    EditDistance[] editDistances;
    foreach (target; results)
    {
        long longestLength = target.targetName.length > location.length ? target.targetName.length
            : location.length;
        editDistances ~= EditDistance(
            levenshteinDistance(target.targetName.toUpper(), location.toUpper()) / (
                cast(float) longestLength),
            target
        );
    }
    editDistances.sort!("a.distance < b.distance");

    // get the url of the target xml resource
    string targetUrl;
    if (editDistances[0].distance <= 0.1)
    targetUrl = editDistances[0].target.targetUrl;
    else
        targetUrl = "https://w1.weather.gov/xml/current_obs/" ~ location ~ ".xml";

    // get the response data from the remote target
    Request request = Request();
    Response response = request.get(targetUrl);
    assert(response.code == 200);

    // parse the response body for a list of localities
    string[string] data;
    auto document = parseDOM(cast(string) response.responseBody);
    assert(document.children[1].name == "current_observation");
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
    if ("wind_gust_mph" in data)
        writeln("Wind:            ", data["wind_mph"], " MPH ", data["wind_dir"], " ", data["wind_degrees"],
    "° (Gusts to ", data["wind_gust_mph"], " MPH)");
    else
        writeln("Wind:            ", data["wind_mph"], " MPH ", data["wind_dir"], " ", data["wind_degrees"], "°");
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

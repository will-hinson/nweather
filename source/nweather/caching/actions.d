module source.nweather.caching.actions;

import std.logger;
import std.string : strip;

import d2sqlite3;
import html.dom;
import requests;

import source.nweather.caching.database;
import source.nweather.models.cacheupdate;
import source.nweather.models.locality;
import source.nweather.models.target;

// temp
import core.stdc.stdlib : exit;
import std.stdio;

private void ensureCacheTable(d2sqlite3.database.Database db)
{
    if (!db.tableExists(CacheUpdate.tableName))
    {
        db.run(CacheUpdate.createTableQuery);
        log("Created table " ~ CacheUpdate.createTableQuery);
    }
}

private Locality[] fetchLocalities()
{
    // get the page that should contain the list of localities and ensure we got a 200
    Request request = Request();
    Response response = request.get("https://w1.weather.gov/xml/current_obs/seek.php");

    assert(response.code == 200);

    // parse the response body for a list of localities
    auto document = createDocument(cast(string) response.responseBody);
    Locality[] localities;
    foreach (localityTag; document.querySelector("select:state").children())
    {
        // skip the default "- Select a State" text
        if (localityTag["value"].strip().length == 0)
        continue;

        localities ~= new Locality(
            cast(string) localityTag["value"].strip(),
            cast(string) localityTag.text.strip()
        );
    }

    return localities;
}

private Target[] fetchTargetsForLocality(Locality locality)
{
    // fetch the page containing the list of targets for this locality
    string targetUrl = "https://w1.weather.gov/xml/current_obs/seek.php?state=" ~ locality
        .localityID ~ "&Find=Find";
    Request request = Request();
    Response response = request.get(targetUrl);

    assert(response.code == 200);

    // parse the response body for a list of localities
    auto document = createDocument(cast(string) response.responseBody);
    string[] targetNames;
    string[] targetUrls;
    foreach (tdTarget; document.querySelectorAll("td"))
    {
        switch (tdTarget["headers"].strip())
        {
        case "Station Name":
            targetNames ~= cast(string) tdTarget.text;
            break;

            case "xml":
            targetUrls ~= "https://w1.weather.gov/xml/current_obs/" ~ cast(
                string) tdTarget.children()
                .front.children().front["href"];
            break;

            default:
            break;
        }
    }
    assert(targetNames.length == targetUrls.length);

    // convert all of the results into Target instances
    Target[] targets;
    for (int n = 0; n < targetNames.length; n++)
        targets ~= new Target(
            -1,
            targetNames[n][0 .. $ - 6].strip(),
            locality.localityID,
            targetUrls[n].strip()
        );

    return targets;
}

Target[] getKnownTargets(d2sqlite3.database.Database db)
{
    ResultRange results = db.execute("SELECT * FROM Targets;");
    Target[] targets;
    foreach (result; results)
    {
        targets ~= new Target(
            result["TargetID"].as!int,
            result["TargetName"].as!string,
            result["TargetLocality"].as!string,
            result["TargetUrl"].as!string
        );
    }

    return targets;
}

CacheUpdate updateCache()
{
    // get the most recent cache update
    auto db = getCacheDatabase();
    db.begin();
    CacheUpdate lastUpdate;

    // create a new cache if there wasn't one
    if ((lastUpdate = db.getLastCacheUpdate()) is null)
    {
        log("Updating cache");
        writeln("nweather: Updating cache (This is one-time and may take a moment)");

        // ensure the cache table exists
        db.ensureCacheTable();

        // create a new cache update record to represent this cache update
        db.run("INSERT INTO `" ~ CacheUpdate.tableName ~ "` (Notes) VALUES ('');");
        lastUpdate = db.getLastCacheUpdate();

        // update the localities table
        Locality[] localities = db.updateLocalities();

        // update the targets table
        db.updateTargets(localities);
    }

    db.commit();
    db.close();
    return lastUpdate;
}

private Locality[] updateLocalities(d2sqlite3.database.Database db)
{
    // drop/recreate the existing localities table
    db.run("DROP TABLE IF EXISTS `" ~ Locality.tableName ~ "`;");
    db.run(Locality.createTableQuery);

    Locality[] localities = fetchLocalities();
    foreach (locality; localities)
    {
        auto query = db.prepare("INSERT INTO `" ~ Locality.tableName ~ "`\nVALUES\n(?, ?);");
        query.bindAll(
            locality.localityID,
            locality.localityName
        );
        query.execute();
    }

    log("Updated localities");
    return localities;
}

private void updateTargets(d2sqlite3.database.Database db, Locality[] localities)
{
    // drop/recreate the existing targets table
    db.run("DROP TABLE IF EXISTS `" ~ Target.tableName ~ "`;");
    db.run(Target.createTableQuery);

    foreach (locality; localities)
    {
        log("Updating targets for locality " ~ locality.localityName);
        foreach (target; locality.fetchTargetsForLocality())
        {
            auto query = db.prepare(
                "INSERT INTO `" ~ Target.tableName ~ "` (\n"
                    ~ " TargetName, TargetLocality, TargetUrl\n"
                    ~ ")"
                    ~ "VALUES\n"
                    ~ "(?, ?, ?);"
            );
            query.bindAll(
                target.targetName,
                target.targetLocality,
                target.targetUrl
            );
            query.execute();
        }
    }

    log("Updated targets");
}

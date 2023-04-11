module source.nweather.caching.database;

import d2sqlite3;

import std.array : replace;
import std.datetime : DateTime;
import std.file : exists, isDir, mkdir;
import std.logger;
import std.path;

import source.nweather.models.cacheupdate;

// temp
import std.stdio;

private string defaultCacheDirectory()
{
    return expandTilde("~/.nweather");
}

private string defaultCachePath(string targetDirectory)
{
    return defaultCacheDirectory() ~ dirSeparator ~ "cache.sqlite3";
}

private void ensureCacheDirectory(string targetDirectory)
{
    if (targetDirectory.exists() && targetDirectory.isDir())
        return;

    if (targetDirectory.exists())
        error("Target cache directory " ~ targetDirectory ~ " already exists as a file");
    else
    {
        mkdir(targetDirectory);
        log("Created cache directory " ~ targetDirectory);
    }
}

d2sqlite3.database.Database getCacheDatabase(string targetDirectory = defaultCacheDirectory())
{
    // ensure that the cache directory already exists
    ensureCacheDirectory(targetDirectory);

    // open a sqlite connection on the default cache database
    return Database(defaultCachePath(targetDirectory));
}

CacheUpdate getLastCacheUpdate(d2sqlite3.database.Database db)
{
    if (!tableExists(db, CacheUpdate.tableName))
        return null;

    ResultRange results = db.execute(
        "SELECT * FROM `" ~ CacheUpdate.tableName ~ "` ORDER BY UpdateDateTime DESC LIMIT 0, 1;"
    );
    if (results.empty)
        return null;

    return new CacheUpdate(
        results.front["UpdateID"].as!int,
        DateTime.fromISOExtString(results.front["UpdateDateTime"].as!string.replace(" ", "T")),
    results.front["Notes"].as!string
    );
}

bool tableExists(d2sqlite3.database.Database db, string tableName)
{
    return !db.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='" ~ tableName ~ "';"
    ).empty;
}

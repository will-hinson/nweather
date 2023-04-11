module source.nweather.models.cacheupdate;

import std.datetime;

class CacheUpdate
{
public:
    static immutable string createTableQuery = (
        "CREATE TABLE `CacheUpdates` (\n"
            ~ "   UpdateID        INTEGER PRIMARY KEY AUTOINCREMENT,\n"
            ~ "   UpdateDateTime  DATETIME DEFAULT CURRENT_TIMESTAMP,\n"
            ~ "   Notes           VARCHAR(10) NULL"
            ~ ");"
    );
    static immutable string tableName = "CacheUpdates";

    string notes;
    int updateID;
    DateTime updateDateTime;

    this(int updateID, DateTime updateDateTime, string notes)
    {
        this.updateID = updateID;
        this.updateDateTime = updateDateTime;
        this.notes = notes;
    }
}

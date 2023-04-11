module source.nweather.models.target;

class Target
{
public:
    static immutable string createTableQuery = (
        "CREATE TABLE `Targets` (\n"
            ~ "   TargetID       INTEGER PRIMARY KEY AUTOINCREMENT,\n"
            ~ "   TargetName     NVARCHAR(200) NOT NULL,\n"
            ~ "   TargetLocality NVARCHAR(2) NOT NULL,\n"
            ~ "   TargetUrl      NVARCHAR(200) NOT NULL\n"
            ~ ");"
    );
    static immutable string tableName = "Targets";

    int targetID;
    string targetLocality;
    string targetName;
    string targetUrl;

    this(int targetID, string targetName, string targetLocality, string targetUrl)
    {
        this.targetID = targetID;
        this.targetLocality = targetLocality;
        this.targetName = targetName;
        this.targetUrl = targetUrl;
    }
}

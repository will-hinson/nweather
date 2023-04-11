module source.nweather.models.locality;

class Locality
{
public:
    static immutable string createTableQuery = (
        "CREATE TABLE `Localities` (\n"
            ~ "   LocalityID      VARCHAR(2) PRIMARY KEY,\n"
            ~ "   LocalityName    VARCHAR(200) NULL"
            ~ ");"
    );
    static immutable string tableName = "Localities";

    string localityID;
    string localityName;

    this(string localityID, string localityName)
    {
        this.localityID = localityID;
        this.localityName = localityName;
    }
}

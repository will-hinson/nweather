module source.nweather.exceptions.modelexception;

class ModelException : Throwable
{
protected:
    string message;

public:
    this(string message)
    {
        super(message);

        this.message = message;
    }
}

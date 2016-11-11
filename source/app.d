import vibe.http.router : URLRouter;
import vibe.core.core : runTask;
import vibe.core.log;
import vibe.http.fileserver : serveStaticFiles;
import vibe.http.server : HTTPServerSettings, listenHTTP;
import vibe.web.rest : registerRestInterface, RestInterfaceClient;
import vibe.db.mongo.mongo : connectMongoDB;
import vibe.data.bson : deserializeBson;
import std.format : format;
import std.algorithm.comparison : min;

interface ILoremSongAPI
{
    string getSong(string theme, int count);
    string[] getThemes();
}

shared static this()
{
    auto router = new URLRouter;
    router
        .get("*", serveStaticFiles("./public/"))
        .registerRestInterface(new LoremSongAPI);

    auto settings = new HTTPServerSettings();
    settings.port = 80;

    if (useLocalIpForTesting)
        settings.bindAddresses = ["::1", "127.0.0.1", "10.23.6.219"];
    else
        settings.bindAddresses = ["0.0.0.0"];

    listenHTTP(settings, router);

    runTestConnection();
}

class LoremSongAPI : ILoremSongAPI
{
    string getSong(string theme, int count)
    {
        import std.array : array;
        import std.random : randomSample, randomCover;

        auto client = getDB();
        auto songs = client.getCollection("lorem.songs");
        auto song = songs.findOne(["theme" : ["$eq" : theme]]);
        auto verses = song["data"].deserializeBson!(string[]);
        auto selection = verses
            .randomSample(min(count, verses.length))
            .array
            .randomCover();

        string[] result;

        foreach (verse; selection)
            result ~= "<div>%s</div>".format(verse);

        return "%-(%s\n%)".format(result);
    }

    string[] getThemes()
    {
        auto client = getDB();
        auto songs = client.getCollection("lorem.songs");
        auto themes = songs.find(cast(string[string])null, ["theme" : 1, "_id" : 0]);

        string[] result;

        foreach (value; themes)
            result ~= value["theme"].get!string;

        return result;
    }

    auto getDB()
    {
        if (useLocalIpForTesting)
            return connectMongoDB("127.0.0.1", 27017);
        else
            return connectMongoDB("mongodb");
    }
}

bool useLocalIpForTesting()
{
    import std.getopt : getopt;
    import core.runtime : Runtime;

    auto args = Runtime.args;

    bool test;
    getopt(args, "test", &test);

    return test;
}

void runTestConnection()
{
    runTask(
    {
        logInfo("Creating a test");
        auto client = new RestInterfaceClient!ILoremSongAPI("http://127.0.0.1:80");
        auto song = client.getSong("Random", 3);
        logInfo("%s", song);

        auto themes = client.getThemes();
        logInfo("%s", themes);

    });
}

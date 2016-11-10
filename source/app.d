import vibe.http.router : URLRouter;
import vibe.http.fileserver : serveStaticFiles;
import vibe.http.server : HTTPServerSettings, listenHTTP;
import vibe.web.rest : registerRestInterface;
import vibe.db.mongo.mongo : connectMongoDB;
import vibe.data.bson : deserializeBson;
import std.format : format;
import std.algorithm.comparison : min;

interface ILoremSongAPI
{
    string getSong(string theme, int count);
}

shared static this()
{
    auto router = new URLRouter;
    router
        .get("*", serveStaticFiles("./public/"))
        .registerRestInterface(new LoremSongAPI);

    auto settings = new HTTPServerSettings();
    settings.port = 8080;

    if (useLocalIpForTesting)
        settings.bindAddresses = ["::1", "127.0.0.1", "10.23.6.219"];
    else
        settings.bindAddresses = ["::1", "127.0.0.1"];

    listenHTTP(settings, router);
}

class LoremSongAPI : ILoremSongAPI
{
    string getSong(string theme, int count)
    {
        auto client = connectMongoDB("127.0.0.1", 27017);
        auto songs = client.getCollection("lorem.songs");
        auto song = songs.findOne(["theme" : ["$eq" : theme]]);
        auto verses = song["data"].deserializeBson!(string[]);

        string[] result;

        foreach (i; 0 .. min(count, verses.length))
            result ~= "<div>%s</div>".format(verses[i]);

        return "%-(%s\n%)".format(result);
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

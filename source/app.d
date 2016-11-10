import vibe.core.core;
import vibe.core.log;
import vibe.http.router;
import vibe.http.server;
import vibe.web.rest;
import vibe.http.fileserver;

interface ILoremSongAPI
{
	string getSong(string theme, int count);
}

class LoremSongAPI : ILoremSongAPI
{
	string getSong(string theme, int count)
    {
        import std.format : format;
        return format("Requested: theme=%s, count=%s",
            theme, count);
    }
}

shared static this()
{
	import std.getopt : getopt;
	import core.runtime : Runtime;
	auto args = Runtime.args;
	bool test;
 	getopt(args, "test", &test);

	auto router = new URLRouter;
	router.registerRestInterface(new LoremSongAPI);
	router.get("*", serveStaticFiles("./public/"));
	auto settings = new HTTPServerSettings;
	settings.port = 8080;

	if (test)
		settings.bindAddresses = ["::1", "127.0.0.1", "10.23.6.219"];
	else
		settings.bindAddresses = ["::1", "127.0.0.1"];

	listenHTTP(settings, router);

	// create a client to talk to the API implementation over the REST interface
	runTask({
		auto client = new RestInterfaceClient!ILoremSongAPI("http://127.0.0.1:8080/");
		auto song = client.getSong("love", 3);
		logInfo("Song: %s", song);
	});
}

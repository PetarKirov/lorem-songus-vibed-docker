FROM mongo

COPY ./songs.json /tmp/songs.json

CMD mongoimport --host mongodb --jsonArray --db lorem --file /tmp/songs.json

## How to run

```docker compose up```

In order to connect to db 

```psql -h localhost -p 5432 -d social_network -U root -W```

And enter password ```root```

### Test cases

Fixtures are loaded automatically. Test queries for testing triggers, functions and procedures are located in ```./testing.sql```
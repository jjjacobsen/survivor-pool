# survivor-pool

Survivor Pool App for the TV Show Survivor

## Development commands in [mise.toml](mise.toml)

## Setting admin account

To keep things simple making an admin account requires manually setting the DB

```bash
db.users.updateOne({email: "your@email.com"}, {$set: {is_admin: true}})
```

## Alternative ways to run the frontend

Since flutter has multiple targets, you can run it multiple different ways. The default is ios but here are other ways to run

- As a generic web server for any browser

    ```bash
    flutter run -d web-server
    ```

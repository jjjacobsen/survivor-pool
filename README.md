# survivor-pool

Survivor Pool App for the TV Show Survivor

## Development commands in [mise.toml](mise.toml)

## Setting admin account

To keep things simple making an admin account requires manually setting the DB

```bash
db.users.updateOne({email: "your@email.com"}, {$set: {is_admin: true}})
```
